// Bridge tests. Build together with DrpcBridge.cs and -define:DRPC_TCP_TEST,
// then run against tests/fake_discord.py. See tests/run.sh.
//
//   BridgeTests.exe PORT CONTROL_FILE [offline|main|badid]

using System;
using System.IO;
using System.Threading;
using Drpc;

static class BridgeTests
{
    const string AppId = "1558853253620564039";
    const string Busy = "{\"details\":\"Running a.m\",\"timestamps\":{\"start\":1234567890123}}";
    static int failures;
    static readonly DateTime t0 = DateTime.UtcNow;

    static int Main(string[] args)
    {
        Bridge.TestPort = int.Parse(args[0]);
        string control = args[1];
        string suite = args.Length > 2 ? args[2] : "main";

        // short timings so the suite runs in ~25 s: stale after 1.5 s,
        // watchdog after 4 s, CPU rule off, at most one update per second
        Bridge.Configure(1.5, 4, 1000, 1);

        if (suite == "offline") Offline();
        else if (suite == "badid") BadId();
        else Online(control);

        Console.WriteLine(failures == 0 ? "PASS " + suite : failures + " FAILED in " + suite);
        return failures == 0 ? 0 : 1;
    }

    static void Offline()
    {
        Bridge.Start(AppId);
        Bridge.Push("{\"details\":\"Editing a.m\"}", Busy);
        Wait(2.5);
        Check("reports Discord missing", Bridge.Status == "Discord is not running");
        Check("not connected", !Bridge.Connected);
        Bridge.Stop();
        Check("stops cleanly", Bridge.Status == "Stopped");
    }

    static void BadId()
    {
        Bridge.Start("1111111111111111111");
        Bridge.Push("{\"details\":\"x1\"}", null);
        Wait(1.5);
        Check("rejected id is reported", Bridge.Status == "Discord rejected the application id");
        Check("Discord's message is kept", Bridge.LastError == "Invalid Client ID");
        Bridge.Stop();

        Bridge.Start("not-a-number");
        Bridge.Push("{\"details\":\"x1\"}", null);
        Wait(0.5);
        Check("malformed id is caught locally", Bridge.Status == "Invalid application id");
        Bridge.Stop();
    }

    static void Online(string control)
    {
        Bridge.Start(AppId);
        Wait(0.5);
        Check("waits for MATLAB before connecting", !Bridge.Connected);

        Bridge.Push(Activity("Editing a.m", "Line 1"), Busy);
        Wait(1.0);
        Check("connects and reads the user", Bridge.Status == "Connected as akeanti");
        Check("first activity shown", Bridge.Shown.Contains("Line 1"));

        int before = Bridge.Updates;
        for (int i = 2; i <= 6; i++) { Bridge.Push(Activity("Editing a.m", "Line " + i), Busy); Wait(0.25); }
        Wait(1.3);
        int sent = Bridge.Updates - before;
        Check("bursts are rate limited (" + sent + " sent for 5 changes)", sent >= 1 && sent <= 3);
        Check("last change wins", Bridge.Shown.Contains("Line 6"));

        Wait(5.5);   // no heartbeat: MATLAB looks busy
        Check("watchdog takes over", Bridge.WatchdogActive);
        Check("busy activity shown", Bridge.Shown.Contains("Running a.m"));
        Check("run start filled in", !Bridge.Shown.Contains("1234567890123") && Bridge.Shown.Contains("\"start\":"));

        Bridge.Push(Activity("Editing a.m", "Line 6"), Busy);
        Wait(1.3);
        Check("heartbeat ends the watchdog", !Bridge.WatchdogActive);
        Check("normal activity is back", Bridge.Shown.Contains("Editing a.m"));

        Bridge.Push("{\"details\":\"BAD\"}", Busy);
        Wait(1.3);
        Check("Discord errors are surfaced", Bridge.LastError.Length > 0);
        Bridge.Push(Activity("Editing b.m", null), Busy);
        Wait(1.3);
        Check("error clears after a good update", Bridge.LastError == "");
        Check("good update shown", Bridge.Shown.Contains("b.m"));

        Bridge.Pause(true);
        Wait(1.3);
        Check("pause clears the activity", Bridge.Shown == "" && Bridge.Status == "Paused");
        Bridge.Pause(false);
        Bridge.Push(Activity("Editing b.m", null), Busy);
        Wait(1.3);
        Check("resume shows it again", Bridge.Shown.Contains("b.m"));

        File.WriteAllText(control, "drop");
        Wait(1.0);
        Check("notices Discord going away", !Bridge.Connected);
        for (int i = 0; i < 10; i++) { Bridge.Push(Activity("Editing b.m", null), Busy); Wait(0.5); }
        Check("reconnects on its own", Bridge.Connected && Bridge.Shown.Contains("b.m"));

        Bridge.Stop();
        Check("stop", Bridge.Status == "Stopped" && Bridge.Shown == "");

        Wait(4.5);   // the last heartbeat is now older than the watchdog limit
        Bridge.Start(AppId);
        Wait(1.0);
        Check("restart does not replay the old run", !Bridge.WatchdogActive && Bridge.Shown == "" && !Bridge.Connected);
        Bridge.Push(Activity("Editing c.m", null), Busy);
        Wait(1.2);
        Check("starts again after stop", Bridge.Shown.Contains("c.m"));
        Bridge.Stop();
    }

    static string Activity(string details, string state)
    {
        return "{\"details\":\"" + details + "\"" + (state == null ? "" : ",\"state\":\"" + state + "\"") + "}";
    }

    static void Check(string what, bool ok)
    {
        if (!ok) failures++;
        Console.WriteLine("{0,5:0.0}s  {1}  {2}{3}", (DateTime.UtcNow - t0).TotalSeconds, ok ? "ok  " : "FAIL", what,
            ok ? "" : "   [status=" + Bridge.Status + " shown=" + Bridge.Shown + " err=" + Bridge.LastError + "]");
    }

    static void Wait(double seconds) { Thread.Sleep((int)(seconds * 1000)); }
}
