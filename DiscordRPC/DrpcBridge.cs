// DrpcBridge.cs - Discord IPC bridge for drpc.m (Discord Rich Presence for MATLAB)
//
// drpc.m compiles this once with the csc.exe that ships with Windows
// (.NET Framework 4) and loads it with NET.addAssembly. All pipe I/O runs on
// background threads, so MATLAB never waits on Discord. A watchdog keeps
// the presence honest while MATLAB is busy running code and cannot report.
//
// Keep to C# 5 syntax (no $"", ?., =>, out var).

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace Drpc
{
    public static class Bridge
    {
        const string Version = "1.0.0";

        // drpc.m puts this in timestamps.start of the busy payload; it is
        // replaced with the moment MATLAB stopped answering.
        const string StartToken = "1234567890123";

        static readonly object gate = new object();
        static readonly AutoResetEvent wake = new AutoResetEvent(false);
        static readonly int self = Process.GetCurrentProcess().Id;

        static Thread worker;
        static int generation;
        static bool running;
        static string clientId = "";
        static bool reconnect;
        static string normal, busy;
        static DateTime lastBeat = DateTime.MinValue;
        static bool paused;
        static double staleAfter = 4, hardStaleAfter = 15, busyCpu = 20, minGap = 5;

        static string status = "Stopped", user = "", lastError = "", shown = "";
        static bool connected;
        static double cpu;
        static bool watchdog;
        static long watchdogSince;
        static int updates;

#if DRPC_TCP_TEST
        public static int TestPort = 46300;
#endif

        // ------------------------------------------------------------ MATLAB API

        public static void Start(string id)
        {
            lock (gate)
            {
                id = (id ?? "").Trim();
                if (id != clientId) { clientId = id; reconnect = true; }
                if (running) return;
                running = true;
                status = "Starting";
                int gen = ++generation;
                worker = new Thread(delegate () { Loop(gen); });
                worker.IsBackground = true;
                worker.Name = "drpc-worker";
                worker.Start();
            }
        }

        public static void Stop()
        {
            Thread t;
            lock (gate)
            {
                if (!running) return;
                running = false;
                t = worker;
                worker = null;
            }
            wake.Set();
            if (t != null) t.Join(3000);
        }

        /// <summary>Heartbeat plus the payloads to show (JSON activity objects).</summary>
        public static void Push(string normalJson, string busyJson)
        {
            lock (gate)
            {
                normal = Blank(normalJson) ? null : normalJson;
                busy = Blank(busyJson) ? null : busyJson;
                lastBeat = DateTime.UtcNow;
            }
            wake.Set();
        }

        /// <summary>Heartbeat without new payloads.</summary>
        public static void Beat()
        {
            lock (gate) lastBeat = DateTime.UtcNow;
        }

        public static void Pause(bool on)
        {
            lock (gate) paused = on;
            wake.Set();
        }

        public static void Configure(double staleSeconds, double hardStaleSeconds, double busyCpuPercent, double minGapSeconds)
        {
            lock (gate)
            {
                staleAfter = Math.Max(1, staleSeconds);
                hardStaleAfter = Math.Max(staleAfter, hardStaleSeconds);
                busyCpu = Math.Max(0, busyCpuPercent);
                minGap = Math.Max(0.5, minGapSeconds);
            }
        }

        public static string BridgeVersion { get { return Version; } }
        public static string Status { get { lock (gate) return status; } }
        public static string User { get { lock (gate) return user; } }
        public static string LastError { get { lock (gate) return lastError; } }
        public static string Shown { get { lock (gate) return shown; } }
        public static bool Connected { get { lock (gate) return connected; } }
        public static bool IsRunning { get { lock (gate) return running; } }
        public static bool Paused { get { lock (gate) return paused; } }
        public static bool WatchdogActive { get { lock (gate) return watchdog; } }
        public static double Cpu { get { lock (gate) return cpu; } }
        public static int Updates { get { lock (gate) return updates; } }
        public static int Pid { get { return self; } }

        public static long ProcessStart()
        {
            try
            {
                using (Process p = Process.GetCurrentProcess())
                    return Epoch(p.StartTime.ToUniversalTime());
            }
            catch { return Epoch(DateTime.UtcNow); }
        }

        public static long Now() { return Epoch(DateTime.UtcNow); }

        // ------------------------------------------------------------ Win32 helpers

        [StructLayout(LayoutKind.Sequential)]
        struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }

        [DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
        [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int max);

        static readonly Dictionary<uint, string> procNames = new Dictionary<uint, string>();

        /// <summary>Seconds since the last keyboard or mouse input anywhere.</summary>
        public static double IdleSeconds()
        {
            try
            {
                LASTINPUTINFO info = new LASTINPUTINFO();
                info.cbSize = (uint)Marshal.SizeOf(info);
                if (!GetLastInputInfo(ref info)) return 0;
                return unchecked((uint)Environment.TickCount - info.dwTime) / 1000.0;
            }
            catch { return 0; }
        }

        /// <summary>"matlab\ttitle", "matlabwindow\ttitle", "other\t" or "".</summary>
        public static string Foreground()
        {
            try
            {
                IntPtr h = GetForegroundWindow();
                if (h == IntPtr.Zero) return "";
                uint pid;
                GetWindowThreadProcessId(h, out pid);
                string kind;
                if (pid == (uint)self) kind = "matlab";
                else if (ProcName(pid).Equals("MATLABWindow", StringComparison.OrdinalIgnoreCase)) kind = "matlabwindow";
                else return "other\t";
                StringBuilder sb = new StringBuilder(512);
                GetWindowText(h, sb, sb.Capacity);
                return kind + "\t" + sb.ToString();
            }
            catch { return ""; }
        }

        static string ProcName(uint pid)
        {
            lock (procNames)
            {
                string name;
                if (procNames.TryGetValue(pid, out name)) return name;
                try { using (Process p = Process.GetProcessById((int)pid)) name = p.ProcessName; }
                catch { name = ""; }
                if (procNames.Count > 256) procNames.Clear();
                procNames[pid] = name;
                return name;
            }
        }

        // ------------------------------------------------------------ worker

        sealed class LoopState
        {
            public Conn Conn;
            public string Current;              // what Discord shows for us (null = nothing)
            public DateTime LastSend = DateTime.MinValue, NextConnect = DateTime.MinValue;
            public Process Me = Process.GetCurrentProcess();
            public TimeSpan CpuTime;
            public DateTime CpuAt = DateTime.UtcNow;
        }

        static void Loop(int gen)
        {
            LoopState st = new LoopState();
            st.CpuTime = CpuTime(st.Me);
            while (true)
            {
                bool keepGoing;
                try { keepGoing = Step(gen, st); }
                catch (Exception ex)
                {
                    lock (gate) lastError = "Bridge: " + ex.Message;
                    keepGoing = true;
                    Thread.Sleep(1000);
                }
                if (!keepGoing) break;
            }

            Conn c = st.Conn;
            if (c != null)
            {
                try
                {
                    if (st.Current != null) c.SetActivity(null);
                    Thread.Sleep(50);
                }
                catch { }
                c.Dispose();
            }
            lock (gate)
            {
                if (gen == generation)
                {
                    connected = false;
                    watchdog = false;
                    shown = "";
                    status = "Stopped";
                }
            }
        }

        static bool Step(int gen, LoopState st)
        {
            DateTime now = DateTime.UtcNow;
            if ((now - st.CpuAt).TotalSeconds >= 2)
            {
                TimeSpan t = CpuTime(st.Me);
                double pct = (t - st.CpuTime).TotalMilliseconds / (now - st.CpuAt).TotalMilliseconds * 100.0;
                st.CpuTime = t;
                st.CpuAt = now;
                lock (gate) cpu = Math.Max(0, pct);
            }

            string want, id;
            bool redo;
            double gap;
            lock (gate)
            {
                if (!running || gen != generation) return false;
                id = clientId;
                redo = reconnect;
                reconnect = false;
                gap = minGap;

                double stale = lastBeat == DateTime.MinValue ? 0 : (now - lastBeat).TotalSeconds;
                if (stale <= staleAfter) watchdog = false;
                else if (!watchdog && busy != null && (stale >= hardStaleAfter || cpu >= busyCpu))
                {
                    watchdog = true;
                    watchdogSince = Epoch(lastBeat);
                }

                if (paused) want = null;
                else if (watchdog) want = busy.Replace(StartToken, watchdogSince.ToString());
                else want = normal;
                if (paused && !connected) status = "Paused";
            }

            if (redo && st.Conn != null)
            {
                st.Conn.Dispose();
                st.Conn = null;
                st.Current = null;
                st.NextConnect = now;
                SetState(false, "Reconnecting");
            }

            if (st.Conn != null && !st.Conn.Alive)
            {
                lock (gate) if (st.Conn.Error != "") lastError = st.Conn.Error;
                st.Conn.Dispose();
                st.Conn = null;
                st.Current = null;
                st.NextConnect = now.AddSeconds(3);
                SetState(false, "Discord closed the connection, retrying");
            }

            if (st.Conn == null && want != null && now >= st.NextConnect)
            {
                st.Conn = Connect(id);
                st.Current = null;
                st.NextConnect = DateTime.UtcNow.AddSeconds(st.Conn == null ? 10 : 0);
            }

            Conn c = st.Conn;
            if (c != null && c.Alive && !string.Equals(want, st.Current) && (now - st.LastSend).TotalSeconds >= gap)
            {
                if (c.SetActivity(want))
                {
                    st.Current = want;
                    st.LastSend = now;
                    lock (gate)
                    {
                        updates++;
                        if (want == null) { shown = ""; status = "Paused"; }
                        else if (connected) status = "Connected as " + user;
                    }
                }
            }

            if (c != null)
            {
                string result = c.TakeResult();
                if (result != null)
                    lock (gate)
                    {
                        if (result == "ok") { lastError = ""; shown = st.Current ?? ""; }
                        else lastError = result;
                    }
            }

            wake.WaitOne(c != null || want != null ? 250 : 1000);
            return true;
        }

        static Conn Connect(string id)
        {
            if (!Regex.IsMatch(id ?? "", "^[0-9]{15,22}$"))
            {
                SetState(false, "Invalid application id");
                return null;
            }
            SetState(false, "Connecting");
            bool sawPipe = false;
            for (int i = 0; i < 10; i++)
            {
                Stream s = OpenPipe(i);
                if (s == null) continue;
                sawPipe = true;
                Conn c = new Conn(s);
                if (c.Handshake(id))
                {
                    lock (gate)
                    {
                        user = c.User == "" ? "Discord user" : c.User;
                        connected = true;
                        status = "Connected as " + user;
                        lastError = "";
                    }
                    return c;
                }
                bool badId = c.InvalidId;
                string err = c.Error;
                c.Dispose();
                if (badId)
                {
                    lock (gate) lastError = err;
                    SetState(false, "Discord rejected the application id");
                    return null;
                }
            }
            SetState(false, sawPipe ? "Discord did not answer, retrying" : "Discord is not running");
            return null;
        }

        static Stream OpenPipe(int i)
        {
#if DRPC_TCP_TEST
            try
            {
                System.Net.Sockets.TcpClient tcp = new System.Net.Sockets.TcpClient();
                tcp.Connect("127.0.0.1", TestPort + i);
                return tcp.GetStream();
            }
            catch { return null; }
#else
            NamedPipeClientStream p = null;
            try
            {
                p = new NamedPipeClientStream(".", "discord-ipc-" + i, PipeDirection.InOut, PipeOptions.Asynchronous);
                p.Connect(150);
                return p;
            }
            catch
            {
                if (p != null) p.Dispose();
                return null;
            }
#endif
        }

        static void SetState(bool isConnected, string text)
        {
            lock (gate)
            {
                connected = isConnected;
                if (!isConnected) shown = "";
                status = text;
            }
        }

        static TimeSpan CpuTime(Process p)
        {
            try { p.Refresh(); return p.TotalProcessorTime; }
            catch { return TimeSpan.Zero; }
        }

        static long Epoch(DateTime utc)
        {
            return (long)(utc - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds;
        }

        static bool Blank(string s) { return s == null || s.Trim().Length == 0; }

        // ------------------------------------------------------------ connection

        sealed class Conn : IDisposable
        {
            static int nonce;
            readonly Stream stream;
            readonly object writeLock = new object();
            readonly ManualResetEvent ready = new ManualResetEvent(false);
            readonly Thread reader;
            volatile bool alive = true;
            volatile bool isReady;
            string result;                    // "ok", an error message, or null
            readonly object resultLock = new object();

            public string User = "";
            public string Error = "";
            public bool InvalidId;

            public Conn(Stream s)
            {
                stream = s;
                reader = new Thread(Read);
                reader.IsBackground = true;
                reader.Name = "drpc-reader";
                reader.Start();
            }

            public bool Alive { get { return alive; } }

            public bool Handshake(string id)
            {
                if (!Write(0, "{\"v\":1,\"client_id\":\"" + id + "\"}")) return false;
                ready.WaitOne(5000);
                return alive && isReady;
            }

            public bool SetActivity(string activityJson)
            {
                string args = "{\"pid\":" + self + (activityJson == null ? "" : ",\"activity\":" + activityJson) + "}";
                int n = Interlocked.Increment(ref nonce);
                return Write(1, "{\"cmd\":\"SET_ACTIVITY\",\"args\":" + args + ",\"nonce\":\"" + n + "\"}");
            }

            public string TakeResult()
            {
                lock (resultLock)
                {
                    string r = result;
                    result = null;
                    return r;
                }
            }

            bool Write(int op, string json)
            {
                byte[] body = Encoding.UTF8.GetBytes(json);
                byte[] frame = new byte[8 + body.Length];
                Buffer.BlockCopy(BitConverter.GetBytes(op), 0, frame, 0, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(body.Length), 0, frame, 4, 4);
                Buffer.BlockCopy(body, 0, frame, 8, body.Length);
                try
                {
                    lock (writeLock)
                    {
                        stream.Write(frame, 0, frame.Length);
                        stream.Flush();
                    }
                    return true;
                }
                catch
                {
                    alive = false;
                    ready.Set();
                    return false;
                }
            }

            void Read()
            {
                try
                {
                    byte[] head = new byte[8];
                    while (alive)
                    {
                        if (!Fill(head)) break;
                        int op = BitConverter.ToInt32(head, 0);
                        int len = BitConverter.ToInt32(head, 4);
                        if (len < 0 || len > (1 << 20)) break;
                        byte[] body = new byte[len];
                        if (!Fill(body)) break;
                        string json = Encoding.UTF8.GetString(body);

                        if (op == 1) OnFrame(json);
                        else if (op == 2)
                        {
                            Error = Field(json, "message");
                            InvalidId = Field(json, "code") == "4000" && !isReady;
                            break;
                        }
                        else if (op == 3) Write(4, json);
                    }
                }
                catch { }
                alive = false;
                ready.Set();
            }

            void OnFrame(string json)
            {
                string evt = Field(json, "evt");
                if (evt == "READY")
                {
                    string name = Field(json, "global_name");
                    User = name != "" ? name : Field(json, "username");
                    isReady = true;
                    ready.Set();
                }
                else if (evt == "ERROR")
                {
                    string msg = Field(json, "message");
                    if (!isReady) Error = msg;
                    lock (resultLock) result = msg == "" ? "Discord returned an error" : msg;
                }
                else if (Field(json, "cmd") == "SET_ACTIVITY")
                {
                    lock (resultLock) result = "ok";
                }
            }

            bool Fill(byte[] buf)
            {
                int got = 0;
                while (got < buf.Length)
                {
                    int n = stream.Read(buf, got, buf.Length - got);
                    if (n <= 0) return false;
                    got += n;
                }
                return true;
            }

            static string Field(string json, string key)
            {
                Match m = Regex.Match(json, "\"" + key + "\"\\s*:\\s*(\"((?:[^\"\\\\]|\\\\.)*)\"|(-?[0-9]+))");
                if (!m.Success) return "";
                if (m.Groups[3].Success) return m.Groups[3].Value;
                try { return Regex.Unescape(m.Groups[2].Value); }
                catch { return m.Groups[2].Value; }
            }

            public void Dispose()
            {
                alive = false;
                ready.Set();
                try { stream.Dispose(); } catch { }
                reader.Join(500);
            }
        }
    }
}
