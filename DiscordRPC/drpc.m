function varargout = drpc(cmd, varargin)
%DRPC  Discord Rich Presence for MATLAB.
%
%   drpc              status and quick actions
%   drpc start        start (startup.m does this when MATLAB opens)
%   drpc stop         stop and clear your Discord status
%   drpc restart      reload settings and reconnect
%   drpc pause        hide your status for this session
%   drpc resume       show it again
%   drpc names off    hide file, model and figure names (drpc names on)
%   drpc config       open config.json (changes apply within 2 s)
%   drpc preview      show the exact payload and live diagnostics
%   drpc setup        start it with MATLAB (adds a block to startup.m)
%   drpc update       install the newest release from GitHub
%   drpc uninstall    stop it and remove it from startup.m
%   drpc docs         open the documentation
%   drpc version      print the version
%
%   What Discord shows
%     Editing pid_tuner.m       Function . Line 42 of 142 . unsaved
%     Running pid_tuner.m       elapsed time of the run
%     Debugging pid_tuner.m     Paused at line 42
%     Simulating motor_model    Simulink . 45% done
%     Building motor_model      Simulink . 48 blocks
%     Designing app1.mlapp      App Designer
%     Viewing Figure 1: Bode    3 figures open
%     In the Command Window     Folder: lab3 . 14 variables
%     Away from keyboard        after idle_minutes without input
%
%   config.json keys
%     client_id         Discord application id
%     show_names        false shows "Editing a function" instead of names
%     show_line         cursor line in the status
%     show_folder       current folder name
%     hidden_folders    path parts that hide names, e.g. ["Internship"]
%     idle_minutes      minutes without input before "Away" (0 = off)
%     detect_running    show "Running" while code runs
%     busy_cpu_percent  MATLAB CPU % (per core) that counts as running
%     timer             "session" (since MATLAB opened) or "activity"
%     member_list       what the member list shows: "name", "details", "state"
%     buttons           up to 2: [{"label":"GitHub","url":"https://..."}]
%     images            image URL or art asset key per state ("" hides it)
%
%   No Python or extra installs: a small C# bridge is compiled once with
%   the compiler built into Windows and talks to Discord from a background
%   thread, so MATLAB never waits on Discord.
%
%   Docs: https://akeanti.xyz/matlab-discord-rpc/

    if nargin < 1 || isempty(cmd)
        cmd = 'status';
    end
    switch lower(char(cmd))
        case 'start',     startRpc(false);
        case 'autostart', autoStart();
        case 'stop',      stopRpc(); fprintf('Discord RPC stopped.\n');
        case 'restart',   stopRpc(); startRpc(false);
        case 'pause',     setPaused(true);
        case 'resume',    setPaused(false);
        case 'names',     setNames(varargin);
        case 'config',    openConfig();
        case 'preview',   preview();
        case 'status',    showStatus();
        case 'setup',     setupStartup(true);
        case 'uninstall', uninstall();
        case 'update',    updateRpc();
        case 'docs',      web(SITE(), '-browser');
        case 'version',   fprintf('drpc %s\n', VERSION());
        case '__test__'   % lets tests/DrpcTest.m call the local functions below
            fns = localfunctions;
            f = fns{strcmp(cellfun(@func2str, fns, 'UniformOutput', false), varargin{1})};
            [varargout{1:nargout}] = f(varargin{2:end});
        otherwise
            error('drpc:command', 'Unknown command "%s". Type <a href="matlab:help drpc">help drpc</a>.', char(cmd));
    end
end

% =====================================================================
% lifecycle

function v = VERSION()
    v = '1.1.0';
end

function u = REPO()
    u = 'https://github.com/akeanti/matlab-discord-rpc';
end

function u = SITE()
    u = 'https://akeanti.xyz/matlab-discord-rpc/';
end

function r = rootDir()
    r = fileparts(mfilename('fullpath'));
end

function autoStart()
    killTimer('DiscordRPC_boot');
    if ~mayAutoStart()
        return
    end
    scheduleBoot(6, 1);
end

function scheduleBoot(delay, attempt)
    t = timer('Name', 'DiscordRPC_boot', 'StartDelay', delay, 'ExecutionMode', 'singleShot', ...
        'ObjectVisibility', 'off', 'TimerFcn', @(~, ~) bootStart(attempt), ...
        'StopFcn', @(tm, ~) delete(tm));
    start(t);
end

function bootStart(attempt)
    if ~isempty(timerfindall('Name', 'DiscordRPC'))
        return      % already started by hand
    end
    if ~hasDesktop()
        % -nodesktop or a MATLAB Engine session: nothing to show. The new
        % desktop (R2025a+) can take a while to come up, so look again.
        if attempt < 6
            scheduleBoot(10, attempt + 1);
        end
        return
    end
    try
        startRpc(true);
    catch err
        warning('drpc:start', 'Discord RPC did not start: %s', err.message);
    end
end

function tf = mayAutoStart()
    % startup.m also runs in -batch jobs, compiled apps and parallel pool
    % workers. None of those is you sitting at MATLAB.
    tf = true;
    try
        tf = ~(isdeployed || batchStartupOptionUsed);
    catch
    end
    if ~isempty(getenv('PARALLEL_SERVER_DECODE_FUNCTION'))
        tf = false;
    end
end

function tf = hasDesktop()
    tf = false;
    try
        tf = usejava('desktop');
    catch
    end
    if ~tf
        try
            tf = logical(desktop('-inuse'));   % the new desktop in R2025a+
        catch
        end
    end
end

function startRpc(quiet)
    root = rootDir();
    killTimer('DiscordRPC');
    loadBridge(root);

    S = newState(root);
    setappdata(groot, 'drpc_state', S);

    Drpc.Bridge.Configure(4, 15, 20, 5);
    Drpc.Bridge.Pause(false);
    Drpc.Bridge.Start(S.cfg.client_id);

    t = timer('Name', 'DiscordRPC', 'ExecutionMode', 'fixedSpacing', 'Period', 2, ...
        'StartDelay', 0, 'BusyMode', 'drop', 'ObjectVisibility', 'off', ...
        'TimerFcn', @(~, ~) tick());
    start(t);

    if ~quiet
        fprintf('Discord RPC is running. Type <a href="matlab:drpc">drpc</a> for status.\n');
    end
end

function stopRpc()
    killTimer('DiscordRPC_boot');
    killTimer('DiscordRPC');
    try
        Drpc.Bridge.Stop();
    catch
    end
    if isappdata(groot, 'drpc_state')
        rmappdata(groot, 'drpc_state');
    end
end

function killTimer(name)
    t = timerfindall('Name', name);
    if ~isempty(t)
        stop(t);
        delete(t);
    end
end

function setPaused(on)
    S = requireState();
    S.paused = on;
    setappdata(groot, 'drpc_state', S);
    Drpc.Bridge.Pause(on);
    if on
        fprintf('Discord RPC paused. <a href="matlab:drpc resume">Resume</a>\n');
    else
        tick();
        fprintf('Discord RPC resumed.\n');
    end
end

function setNames(args)
    S = requireState();
    if isempty(args)
        on = ~S.cfg.show_names;
    else
        on = any(strcmpi(args{1}, {'on', 'show', 'true', '1'}));
    end
    setConfigValue(S.root, 'show_names', on);
    S.cfg.show_names = on;
    S.cfgStamp = fileStamp(fullfile(S.root, 'config.json'));
    setappdata(groot, 'drpc_state', S);
    tick();
    if on
        fprintf('File names are visible on Discord.\n');
    else
        fprintf('File names are hidden on Discord.\n');
    end
end

function S = requireState()
    S = getappdata(groot, 'drpc_state');
    if isempty(S)
        startRpc(true);
        S = getappdata(groot, 'drpc_state');
    end
end

function setupStartup(verbose)
    f = startupFile();
    txt = '';
    if isfile(f)
        txt = fileread(f);
    end
    writeText(f, withStartupBlock(txt));
    if verbose
        fprintf('Discord RPC will start with MATLAB (%s).\n', f);
    end
end

function txt = withStartupBlock(txt)
    % startup.m text with exactly one drpc block at the end
    txt = regexprep(removeStartupBlock(txt), '\s+$', '');
    if ~isempty(txt)
        txt = [txt newline newline];
    end
    block = strjoin({ ...
        startupMarks(1), ...
        'try', ...
        '    addpath(fullfile(fileparts(mfilename(''fullpath'')), ''DiscordRPC''));', ...
        '    drpc autostart', ...
        'catch drpcErr', ...
        '    warning(''Discord RPC: %s'', drpcErr.message);', ...
        'end', ...
        'clear drpcErr', ...
        startupMarks(2)}, newline);
    txt = [txt block newline];
end

function uninstall()
    stopRpc();
    f = startupFile();
    if isfile(f)
        txt = regexprep(removeStartupBlock(fileread(f)), '\s+$', '');
        if isempty(txt)
            delete(f);
        else
            writeText(f, [txt newline]);
        end
    end
    try
        rmpath(rootDir());
    catch
    end
    fprintf(['Discord RPC is off and will not start with MATLAB.\n' ...
        'To delete the files too, restart MATLAB and remove this folder:\n  %s\n'], rootDir());
end

function updateRpc()
    tag = latestRelease();
    if isempty(tag)
        fprintf('Could not ask GitHub for the newest release. Installing the latest code from main...\n');
        zipUrl = [REPO() '/archive/refs/heads/main.zip'];
    else
        latest = regexprep(tag, '^v', '');
        if ~isNewer(latest, VERSION())
            fprintf('drpc %s is the newest version.\n', VERSION());
            return
        end
        fprintf('Updating drpc %s to %s...\n', VERSION(), latest);
        zipUrl = sprintf('%s/archive/refs/tags/%s.zip', REPO(), tag);
    end
    tmp = tempname;
    mkdir(tmp);
    cleanup = onCleanup(@() removeFolder(tmp));
    unzip(zipUrl, tmp);
    inst = dir(fullfile(tmp, '*', 'install.m'));
    if isempty(inst)
        error('drpc:update', 'The download from %s has no install.m.', zipUrl);
    end
    run(fullfile(inst(1).folder, inst(1).name));
    clear cleanup
end

function tag = latestRelease()
    tag = '';
    try
        api = strrep(REPO(), 'https://github.com/', 'https://api.github.com/repos/');
        r = webread([api '/releases/latest'], weboptions('Timeout', 15, 'ContentType', 'json'));
        tag = char(r.tag_name);
    catch
    end
end

function tf = isNewer(a, b)
    % true if version a is newer than version b ('1.10.0' > '1.9.2')
    pa = str2double(regexp(char(a), '\d+', 'match'));
    pb = str2double(regexp(char(b), '\d+', 'match'));
    n = max(numel(pa), numel(pb));
    pa(end + 1:n) = 0;
    pb(end + 1:n) = 0;
    k = find(pa ~= pb, 1);
    tf = ~isempty(k) && pa(k) > pb(k);
end

function removeFolder(d)
    try
        rmdir(d, 's');
    catch
    end
end

function f = startupFile()
    % startup.m next to the DiscordRPC folder (your MATLAB user folder)
    f = fullfile(fileparts(rootDir()), 'startup.m');
end

function m = startupMarks(k)
    marks = {'% >>> MATLAB Discord RPC >>>', '% <<< MATLAB Discord RPC <<<'};
    m = marks{k};
end

function txt = removeStartupBlock(txt)
    pat = ['(\r?\n)*' regexptranslate('escape', startupMarks(1)) '.*?' ...
        regexptranslate('escape', startupMarks(2)) '(\r?\n)?'];
    txt = regexprep(txt, pat, newline);
    txt = regexprep(txt, '^\s+', '');
end

function writeText(f, txt)
    fid = fopen(f, 'w', 'n', 'UTF-8');
    if fid < 0
        error('drpc:write', 'Cannot write %s', f);
    end
    fprintf(fid, '%s', txt);
    fclose(fid);
end

% =====================================================================
% bridge

function loadBridge(root)
    try
        v = char(Drpc.Bridge.BridgeVersion);
        if ~strcmp(v, VERSION())
            warning('drpc:bridge', 'Bridge %s is loaded; restart MATLAB to load %s.', v, VERSION());
        end
        return
    catch
    end
    if ~ispc
        error('drpc:platform', 'Discord RPC for MATLAB runs on Windows.');
    end
    NET.addAssembly(compileBridge(root));
end

function dll = compileBridge(root)
    src = fullfile(root, 'DrpcBridge.cs');
    txt = fileread(src);
    h = mod(sum(double(txt) .* mod(1:numel(txt), 9973)), 2^32);
    bin = fullfile(root, 'bin');
    dll = fullfile(bin, sprintf('DrpcBridge_%08x.dll', h));
    if isfile(dll)
        return
    end
    if ~isfolder(bin)
        mkdir(bin);
    end
    fw = fullfile(getenv('WINDIR'), 'Microsoft.NET');
    csc = fullfile(fw, 'Framework64', 'v4.0.30319', 'csc.exe');
    if ~isfile(csc)
        csc = fullfile(fw, 'Framework', 'v4.0.30319', 'csc.exe');
    end
    if ~isfile(csc)
        error('drpc:csc', 'The C# compiler that ships with Windows was not found at %s.', csc);
    end
    % csc's path has no spaces, so it stays unquoted (cmd.exe strips a leading quote)
    cmd = sprintf('%s /nologo /target:library /optimize+ /r:System.Core.dll /out:"%s" "%s"', csc, dll, src);
    [st, out] = system(cmd);
    if st ~= 0 || ~isfile(dll)
        error('drpc:compile', 'Could not build the Discord bridge:\n%s', out);
    end
    % bridges built from older sources; one still loaded in another MATLAB stays
    old = dir(fullfile(bin, 'DrpcBridge_*.dll'));
    ws = warning('off', 'all');
    for k = 1:numel(old)
        if ~strcmp(fullfile(bin, old(k).name), dll)
            try
                delete(fullfile(bin, old(k).name));
            catch
            end
        end
    end
    warning(ws);
end

% =====================================================================
% config

function c = defaultConfig()
    img = @(id) ['https://cdn.discordapp.com/emojis/' id '.png?size=512&quality=lossless'];
    c = struct();
    c.client_id = '1558853253620564039';
    c.show_names = true;
    c.show_line = true;
    c.show_folder = true;
    c.hidden_folders = {};
    c.idle_minutes = 10;
    c.detect_running = true;
    c.busy_cpu_percent = 60;
    c.timer = 'session';
    c.member_list = 'name';
    c.buttons = {};
    im = struct();
    im.matlab   = img('1558854514004463676');
    im.editing  = img('1558854582891843625');
    im.running  = img('1558854587539005572');
    im.debug    = img('1558854580865863742');
    im.simulink = img('1558854589011202109');
    im.app      = img('1558854579305840751');
    im.plot     = img('1558854586175987792');
    im.idle     = img('1558854584326422689');
    c.images = im;
end

function c = starterConfig()
    % what a new config.json holds. client_id and images stay out, so they
    % keep following the defaults unless you add them yourself.
    c = rmfield(defaultConfig(), {'client_id', 'images'});
end

function [c, stamp, problem] = readConfig(root, current)
    % current: the settings to keep when config.json can't be read. Falling
    % back to the defaults would turn hidden names back on after a typo.
    f = fullfile(root, 'config.json');
    def = defaultConfig();
    if nargin < 2
        current = def;
    end
    if ~isfile(f)
        writeConfig(root, starterConfig());
    end
    stamp = fileStamp(f);
    problem = '';
    c = def;
    try
        u = jsondecode(fileread(f));
    catch err
        problem = err.message;
        c = current;
        return
    end
    if ~isstruct(u) || ~isscalar(u)
        problem = 'config.json must hold one JSON object: { ... }';
        c = current;
        return
    end
    fn = fieldnames(u);
    for k = 1:numel(fn)
        key = fn{k};
        if ~isfield(def, key)
            continue
        end
        if strcmp(key, 'images')
            if isstruct(u.images)
                im = fieldnames(u.images);
                for j = 1:numel(im)
                    if ischar(u.images.(im{j}))
                        c.images.(im{j}) = u.images.(im{j});
                    end
                end
            end
        else
            c.(key) = u.(key);
        end
    end
    if ~ischar(c.client_id)
        warning('drpc:config', 'client_id must be a string in quotes; using the default.');
        c.client_id = def.client_id;
    end
    c.hidden_folders = toCellstr(c.hidden_folders);
    c.buttons = buttonList(c.buttons);
    for key = {'show_names', 'show_line', 'show_folder', 'detect_running'}
        c.(key{1}) = isequal(c.(key{1}), true) || isequal(c.(key{1}), 1);
    end
    for key = {'idle_minutes', 'busy_cpu_percent'}
        if ~isnumeric(c.(key{1})) || ~isscalar(c.(key{1}))
            c.(key{1}) = def.(key{1});
        end
    end
end

function writeConfig(root, c)
    writeText(fullfile(root, 'config.json'), [jsonencode(c, 'PrettyPrint', true) newline]);
end

function setConfigValue(root, key, value)
    % Change one key in config.json and leave the rest of the file as it is.
    f = fullfile(root, 'config.json');
    if ~isfile(f)
        writeConfig(root, starterConfig());
    end
    txt = fileread(f);
    try
        u = jsondecode(txt);
    catch err
        error('drpc:config', 'config.json has an error. Fix it first (<a href="matlab:drpc config">drpc config</a>):\n%s', err.message);
    end
    if ~isstruct(u) || ~isscalar(u)
        error('drpc:config', 'config.json must hold one JSON object: { ... }');
    end
    val = jsonencode(value);
    pat = ['("' key '"\s*:\s*)(true|false|null|-?[\d.eE+-]+|"(?:[^"\\]|\\.)*")'];
    if ~isempty(regexp(txt, pat, 'once'))
        out = regexprep(txt, pat, ['$1' regexprep(val, '([$\\])', '\\$1')], 'once');
    else
        out = regexprep(txt, '^(\s*)\{', sprintf('$1{\n  "%s": %s,', key, val), 'once');
    end
    try
        jsondecode(out);
    catch
        % e.g. the file was "{}": rewrite it instead of patching it
        u.(key) = value;
        out = [jsonencode(u, 'PrettyPrint', true) newline];
    end
    writeText(f, out);
end

function s = fileStamp(f)
    % changes whenever the file is saved, even twice within one second
    d = dir(f);
    if isempty(d)
        s = [];
    else
        s = [d.datenum d.bytes];
    end
end

function S = refreshConfig(S)
    stamp = fileStamp(fullfile(S.root, 'config.json'));
    if isempty(stamp) || isequal(stamp, S.cfgStamp)
        return
    end
    oldId = S.cfg.client_id;
    [S.cfg, S.cfgStamp, problem] = readConfig(S.root, S.cfg);
    if ~isempty(problem) && ~strcmp(problem, S.cfgError)
        fprintf(['Discord RPC: config.json has an error, so the previous settings stay on.\n' ...
            '  %s\n  <a href="matlab:drpc config">Open config.json</a>\n'], problem);
    elseif isempty(problem) && ~isempty(S.cfgError)
        fprintf('Discord RPC: config.json is fixed and the new settings are on.\n');
    end
    S.cfgError = problem;
    if ~strcmp(oldId, S.cfg.client_id)
        Drpc.Bridge.Start(S.cfg.client_id);
    end
end

function openConfig()
    f = fullfile(rootDir(), 'config.json');
    if ~isfile(f)
        writeConfig(rootDir(), starterConfig());
    end
    edit(f);
end

function c = toCellstr(x)
    if ischar(x)
        c = {x};
    elseif iscell(x)
        c = x(cellfun(@ischar, x));
        c = c(:)';
    else
        c = {};
    end
end

function b = buttonList(raw)
    b = {};
    if isstruct(raw)
        raw = num2cell(raw);
    end
    if ~iscell(raw)
        return
    end
    for k = 1:numel(raw)
        x = raw{k};
        if isstruct(x) && isfield(x, 'label') && isfield(x, 'url') && ischar(x.label) ...
                && ischar(x.url) && numel(x.label) >= 1 && startsWith(x.url, {'http://', 'https://'})
            b{end + 1} = struct('label', x.label(1:min(end, 32)), 'url', x.url); %#ok<AGROW>
            if numel(b) == 2
                break
            end
        end
    end
end

% =====================================================================
% state

function S = newState(root)
    S = struct();
    S.root = root;
    [S.cfg, S.cfgStamp, S.cfgError] = readConfig(root);
    if ~isempty(S.cfgError)
        % the file might be hiding names, so don't show them until it's fixed
        S.cfg.show_names = false;
        warning('drpc:config', 'config.json could not be read, so names stay hidden until it is fixed: %s', S.cfgError);
    end
    S.session = double(Drpc.Bridge.ProcessStart());
    S.started = double(Drpc.Bridge.Now());
    S.paused = false;
    S.release = releaseText();
    S.kindKey = '';
    S.kindVal = '';
    S.modeKey = '';
    S.modeSince = S.started;
    S.runSince = 0;
    S.cpuHits = 0;
    S.simModel = '';
    S.simSince = 0;
    S.focus = 'editor';
    S.focusClass = '';
    S.fgKind = '';
    S.fgTitle = '';
    S.fgMode = 'main';
    S.fgName = '';
    S.blocks = struct('model', '', 'count', 0, 'at', 0);
    S.debug = struct('active', false, 'file', '', 'dir', '', 'line', 0);
    S.last = struct();
    S.lastBusy = struct();
    S.error = '';
end

function r = releaseText()
    r = ['R' version('-release')];
    tok = regexp(version, '\)\s*(Update \d+)', 'tokens', 'once');
    if ~isempty(tok)
        r = [r ' ' tok{1}];
    end
end

% =====================================================================
% tick

function tick()
    % Must never throw: an error in a TimerFcn stops the timer.
    ws = [];
    try
        ws = warning('off', 'all');
    catch
    end
    S = [];
    try
        S = getappdata(groot, 'drpc_state');
        if isempty(S)
            return
        end
        S = refreshConfig(S);
        [S, act, busyAct] = buildActivity(S);
        S.last = act;
        S.lastBusy = busyAct;
        S.error = '';
        setappdata(groot, 'drpc_state', S);
        Drpc.Bridge.Push(jsonencode(act), jsonencode(busyAct));
    catch err
        try
            if isstruct(S)
                S.error = sprintf('%s (line %d)', err.message, err.stack(1).line);
                setappdata(groot, 'drpc_state', S);
            end
        catch
        end
        try
            Drpc.Bridge.Beat();
        catch
        end
    end
    if ~isempty(ws)
        try
            warning(ws);
        catch
        end
    end
end

function [S, act, busyAct] = buildActivity(S)
    c = S.cfg;
    SEP = [' ' char(183) ' '];
    t = double(Drpc.Bridge.Now());

    [ed, S] = editorInfo(S);
    S = updateFocus(S);
    S = updateForeground(S);
    sl = simulinkInfo();
    S.debug = debugInfo();

    cwd = pwd;
    [~, folder] = fileparts(cwd);
    hidden = isHidden(c.hidden_folders, {cwd, ed.dir, S.debug.dir});
    names = c.show_names && ~hidden;
    showFolder = c.show_folder && ~hidden;
    label = fileLabel(ed, names);
    inEditor = ~isempty(ed.file) && ~strcmp(S.focus, 'cmd');

    idleSec = double(Drpc.Bridge.IdleSeconds());
    idle = c.idle_minutes > 0 && idleSec >= c.idle_minutes * 60;

    cpu = double(Drpc.Bridge.Cpu);
    if c.detect_running && t - S.started > 45 && cpu >= c.busy_cpu_percent
        S.cpuHits = S.cpuHits + 1;
    else
        S.cpuHits = 0;
    end

    if inEditor
        runText = ['Running ' label];
    else
        runText = 'Running code';
    end
    folderText = '';
    if showFolder
        folderText = ['Folder: ' folder];
    end

    mode = '';
    icon = '';
    details = '';
    state = '';
    since = S.session;

    % 1. Simulink simulation
    if ~isempty(sl.running)
        if ~strcmp(S.simModel, sl.running)
            S.simModel = sl.running;
            S.simSince = t;
        end
        mode = 'sim';
        icon = 'simulink';
        details = ['Simulating ' pick(names, sl.running, 'a model')];
        state = 'Simulink';
        if sl.pct >= 0
            state = sprintf('Simulink%s%d%% done', SEP, sl.pct);
        end
        since = S.simSince;
    else
        S.simModel = '';
    end

    % 2. code running while MATLAB still answers (loops with drawnow, pause, plots)
    if isempty(mode) && S.cpuHits >= 2
        if S.runSince == 0
            S.runSince = t - 4;
        end
        mode = 'run';
        icon = 'running';
        details = runText;
        state = folderText;
        since = S.runSince;
    elseif S.cpuHits == 0
        S.runSince = 0;
    end

    % 3. away from keyboard
    if isempty(mode) && idle
        mode = 'idle';
        icon = 'idle';
        details = 'Away from keyboard';
        if names && ~isempty(label)
            state = ['Last on ' label];
        end
        since = t - idleSec;
    end

    % 4. stopped at a breakpoint
    if isempty(mode) && S.debug.active
        mode = 'debug';
        icon = 'debug';
        dl = label;
        if ~isempty(S.debug.file)
            dl = pick(names, S.debug.file, 'code');
        elseif isempty(dl)
            dl = 'code';
        end
        details = ['Debugging ' dl];
        state = 'Paused at a breakpoint';
        if c.show_line && S.debug.line > 0
            state = sprintf('Paused at line %d', S.debug.line);
        end
    end

    % 5. focused window: Simulink, App Designer, figures
    if isempty(mode)
        switch S.fgMode
            case 'simulink'
                mode = 'simulink';
                icon = 'simulink';
                mdl = S.fgName;
                if isempty(mdl)
                    mdl = sl.model;
                end
                details = ['Building ' pick(names, mdl, 'a model')];
                parts = {'Simulink'};
                if ~isempty(mdl)
                    [n, S] = blockCount(S, mdl, t);
                    if n > 0
                        parts{end + 1} = sprintf('%d blocks', n);
                    end
                end
                if sl.models > 1
                    parts{end + 1} = sprintf('%d models open', sl.models);
                end
                state = strjoin(parts, SEP);
            case 'app'
                mode = 'app';
                icon = 'app';
                details = ['Designing ' pick(names, S.fgName, 'an app')];
                state = 'App Designer';
            case 'plot'
                mode = 'plot';
                icon = 'plot';
                details = 'Looking at plots';
                if names && numel(S.fgName) >= 2
                    details = ['Viewing ' S.fgName];
                end
                nf = numel(findall(groot, 'Type', 'figure'));
                if nf > 0
                    state = sprintf('%d figure%s open', nf, plural(nf));
                end
        end
    end

    % 6. editor
    if isempty(mode) && inEditor
        mode = 'edit';
        icon = 'editing';
        details = ['Editing ' label];
        parts = {};
        if names && ~isempty(ed.kind)
            parts{end + 1} = ed.kind;
        end
        if c.show_line && ed.line > 0
            if ed.lines > 0
                parts{end + 1} = sprintf('Line %d of %d', ed.line, ed.lines);
            else
                parts{end + 1} = sprintf('Line %d', ed.line);
            end
        end
        if ed.dirty
            parts{end + 1} = 'unsaved';
        end
        state = strjoin(parts, SEP);
    end

    % 7. command window
    if isempty(mode)
        mode = 'cmd';
        details = 'In the Command Window';
        parts = {};
        if showFolder
            parts{end + 1} = folderText;
        end
        nv = numel(evalin('base', 'who'));
        if nv > 0
            parts{end + 1} = sprintf('%d variable%s', nv, plural(nv));
        end
        state = strjoin(parts, SEP);
    end

    % elapsed timer
    key = [mode '|' details];
    if ~strcmp(key, S.modeKey)
        S.modeKey = key;
        S.modeSince = t;
    end
    if strcmp(mode, 'debug') || (strcmp(c.timer, 'activity') && ~any(strcmp(mode, {'sim', 'run', 'idle'})))
        since = S.modeSince;
    end

    % hover text on the small icon
    hints = {};
    if showFolder && ~any(strcmp(mode, {'cmd', 'run'}))
        hints{end + 1} = folderText;
    end
    if ed.tabs > 1
        hints{end + 1} = sprintf('%d files open', ed.tabs);
    end
    smallText = strjoin(hints, SEP);

    act = makeActivity(c, S, details, state, icon, smallText, int64(since));
    busyHint = 'MATLAB is busy';
    if ~isempty(smallText)
        busyHint = [busyHint SEP smallText];
    end
    busyAct = makeActivity(c, S, runText, folderText, 'running', busyHint, int64(1234567890123));
end

function a = makeActivity(c, S, details, state, icon, smallText, since)
    a = struct();
    a.details = clip(details);
    st = clip(state);
    if ~isempty(st)
        a.state = st;
    end
    a.timestamps = struct('start', since);
    as = struct();
    if isfield(c.images, 'matlab') && numel(c.images.matlab) >= 2
        as.large_image = c.images.matlab;
    end
    as.large_text = clip(['MATLAB ' S.release]);
    if ~isempty(icon) && isfield(c.images, icon) && numel(c.images.(icon)) >= 2
        as.small_image = c.images.(icon);
        txt = clip(smallText);
        if isempty(txt)
            txt = [upper(icon(1)) icon(2:end)];
        end
        as.small_text = txt;
    end
    a.assets = as;
    if ~isempty(c.buttons)
        a.buttons = c.buttons;
    end
    switch lower(char(c.member_list))
        case 'state',   a.status_display_type = int32(1);
        case 'details', a.status_display_type = int32(2);
    end
    a.instance = false;
end

% =====================================================================
% what MATLAB is doing

function [ed, S] = editorInfo(S)
    ed = struct('file', '', 'dir', '', 'ext', '', 'kind', '', 'line', 0, 'lines', 0, 'tabs', 0, 'dirty', false);
    try
        ed.tabs = numel(matlab.desktop.editor.getAll);
        doc = matlab.desktop.editor.getActive;
        if isempty(doc)
            return
        end
        fn = char(doc.Filename);
        [ed.dir, n, e] = fileparts(fn);
        ed.file = [n e];
        ed.ext = lower(e);
        try
            ed.dirty = logical(doc.Modified);
        catch
        end
        txt = '';
        try
            txt = char(doc.Text);
        catch
        end
        if ~isempty(txt)
            ed.lines = sum(txt == newline) + 1;
        end
        try
            sel = doc.Selection;
            ed.line = double(sel(1));
        catch
        end
        key = sprintf('%s|%d', fn, numel(txt));
        if ~strcmp(S.kindKey, key)
            S.kindKey = key;
            S.kindVal = fileKind(ed.ext, txt);
        end
        ed.kind = S.kindVal;
    catch
    end
end

function k = fileKind(ext, txt)
    switch ext
        case '.mlx'
            k = 'Live Script';
        case {'.m', ''}
            k = 'Script';
            first = regexp(txt, '^[ \t]*[^%\s][^\r\n]*', 'match', 'once', 'lineanchors');
            if ~isempty(regexp(first, '^\s*function\>', 'once'))
                k = 'Function';
            elseif ~isempty(regexp(first, '^\s*classdef\>', 'once'))
                k = 'Class';
            end
        case {'.c', '.cpp', '.h', '.hpp'}
            k = 'C/C++ file';
        case '.py'
            k = 'Python file';
        case {'.txt', '.md'}
            k = 'Text file';
        otherwise
            k = [upper(ext(2:end)) ' file'];
    end
end

function s = fileLabel(ed, names)
    if isempty(ed.file)
        s = '';
    elseif names
        s = ed.file;
    elseif any(strcmp(ed.kind, {'Script', 'Function', 'Class', 'Live Script'}))
        s = ['a ' lower(ed.kind)];
    else
        s = 'a file';
    end
end

function S = updateFocus(S)
    % Which part of the desktop has the keyboard (Command Window vs Editor).
    try
        o = java.awt.KeyboardFocusManager.getCurrentKeyboardFocusManager().getFocusOwner();
        if isempty(o)
            return
        end
        cls = char(o.getClass().getName());
        S.focusClass = cls;
        l = lower(cls);
        if contains(l, 'cmdwin') || contains(l, 'commandwindow')
            S.focus = 'cmd';
        elseif contains(l, {'editor', 'syntaxtextpane', 'jxbrowser', 'livecode', 'lightweightbrowser', 'cefbrowser'})
            S.focus = 'editor';
        end
    catch
    end
end

function S = updateForeground(S)
    raw = '';
    try
        raw = char(Drpc.Bridge.Foreground());
    catch
    end
    tab = find(raw == char(9), 1);
    if isempty(tab)
        return
    end
    S.fgKind = raw(1:tab - 1);
    if strcmp(S.fgKind, 'other')
        return      % another app has focus: keep the last MATLAB view
    end
    S.fgTitle = strtrim(raw(tab + 1:end));
    [S.fgMode, S.fgName] = classifyTitle(S.fgKind, S.fgTitle);
end

function [mode, name] = classifyTitle(kind, title)
    mode = 'main';
    name = '';
    tok = regexp(title, '^(.*?)\s+-\s+(Simulink|Stateflow)', 'tokens', 'once');
    if ~isempty(tok)
        mode = 'simulink';
        name = strtrim(strrep(tok{1}, '*', ''));
        name = strtok(name, '/');
        return
    end
    if startsWith(title, 'App Designer')
        mode = 'app';
        idx = strfind(title, ' - ');
        if ~isempty(idx)
            [~, n, e] = fileparts(strtrim(strrep(title(idx(1) + 3:end), '*', '')));
            name = [n e];
        end
        return
    end
    if isFigureTitle(title)
        mode = 'plot';
        name = title;
    end
end

function tf = isFigureTitle(title)
    tf = ~isempty(regexp(title, '^(UI )?Figure( \d+)?(:|$)', 'once'));
    if tf || isempty(title)
        return
    end
    figs = findall(groot, 'Type', 'figure');
    for k = 1:numel(figs)
        try
            f = figs(k);
            nm = char(f.Name);
            if strcmp(char(f.NumberTitle), 'on') && isnumeric(f.Number) && ~isempty(f.Number)
                ft = sprintf('Figure %d', f.Number);
                if ~isempty(nm)
                    ft = [ft ': ' nm]; %#ok<AGROW>
                end
            else
                ft = nm;
            end
            if strcmp(ft, title)
                tf = true;
                return
            end
        catch
        end
    end
end

function sl = simulinkInfo()
    sl = struct('model', '', 'models', 0, 'running', '', 'pct', -1);
    try
        if ~(exist('is_simulink_loaded', 'file') && is_simulink_loaded())
            return
        end
        mdls = find_system('SearchDepth', 0, 'Type', 'block_diagram', 'BlockDiagramType', 'model');
        for k = 1:numel(mdls)
            m = mdls{k};
            if strcmp(get_param(m, 'Open'), 'on')
                sl.models = sl.models + 1;
            end
            if isempty(sl.running) && any(strcmp(get_param(m, 'SimulationStatus'), {'running', 'paused', 'initializing'}))
                sl.running = m;
                try
                    stopT = str2double(get_param(m, 'StopTime'));
                    simT = get_param(m, 'SimulationTime');
                    if isfinite(stopT) && stopT > 0
                        sl.pct = min(100, 5 * floor(20 * simT / stopT));
                    end
                catch
                end
            end
        end
        try
            g = gcs;
            if ~isempty(g)
                sl.model = bdroot(g);
            end
        catch
        end
    catch
    end
end

function [n, S] = blockCount(S, mdl, t)
    if strcmp(S.blocks.model, mdl) && t - S.blocks.at < 60
        n = S.blocks.count;
        return
    end
    n = 0;
    try
        n = numel(find_system(mdl, 'Type', 'Block'));
    catch
    end
    S.blocks = struct('model', mdl, 'count', n, 'at', t);
end

function d = debugInfo()
    d = struct('active', false, 'file', '', 'dir', '', 'line', 0);
    try
        d.active = logical(feature('IsDebugMode'));
    catch
    end
    if ~d.active
        return
    end
    try
        st = dbstack('-completenames');
        me = mfilename('fullpath');
        for k = 1:numel(st)
            f = st(k).file;
            if startsWith(f, me) || startsWith(f, matlabroot)
                continue
            end
            [d.dir, n, e] = fileparts(f);
            d.file = [n e];
            d.line = st(k).line;
            break
        end
    catch
    end
end

% =====================================================================
% helpers

function tf = isHidden(patterns, paths)
    tf = false;
    for p = patterns
        pat = lower(strtrim(p{1}));
        if isempty(pat)
            continue
        end
        for q = paths
            if ~isempty(q{1}) && contains(lower(q{1}), pat)
                tf = true;
                return
            end
        end
    end
end

function s = pick(names, real, generic)
    if names && numel(real) >= 1
        s = real;
    else
        s = generic;
    end
end

function s = plural(n)
    if n == 1
        s = '';
    else
        s = 's';
    end
end

function s = clip(s)
    s = strtrim(char(s));
    if numel(s) < 2
        s = '';
    elseif numel(s) > 128
        s = [s(1:127) char(8230)];
    end
end

% =====================================================================
% status

function showStatus()
    fprintf('\n  <strong>Discord Rich Presence</strong> for MATLAB  v%s\n\n', VERSION());
    S = getappdata(groot, 'drpc_state');
    if isempty(S) || isempty(timerfindall('Name', 'DiscordRPC'))
        fprintf('  Not running.  <a href="matlab:drpc start">Start</a>\n\n');
        return
    end
    row('Discord', char(Drpc.Bridge.Status));
    shown = char(Drpc.Bridge.Shown);
    if ~isempty(shown)
        a = jsondecode(shown);
        row('Showing', a.details);
        if isfield(a, 'state')
            row('', a.state);
        end
        if Drpc.Bridge.WatchdogActive
            row('', '(MATLAB is busy, shown by the watchdog)');
        end
    elseif isfield(S.last, 'details') && ~S.paused
        row('Next', S.last.details);
    end
    err = char(Drpc.Bridge.LastError);
    if ~isempty(err)
        row('Discord said', err);
    end
    if ~isempty(S.error)
        row('Error', S.error);
    end
    row('Settings', sprintf('<a href="matlab:drpc config">config.json</a>  (names %s, idle after %g min)', ...
        onOff(S.cfg.show_names), S.cfg.idle_minutes));
    if ~isempty(S.cfgError)
        row('', ['config.json has an error: ' S.cfgError]);
    end
    if S.paused
        pr = '<a href="matlab:drpc resume">resume</a>';
    else
        pr = '<a href="matlab:drpc pause">pause</a>';
    end
    if S.cfg.show_names
        nm = '<a href="matlab:drpc names off">hide names</a>';
    else
        nm = '<a href="matlab:drpc names on">show names</a>';
    end
    fprintf('\n  %s   %s   <a href="matlab:drpc preview">preview</a>   <a href="matlab:drpc restart">restart</a>   <a href="matlab:drpc stop">stop</a>   <a href="matlab:drpc docs">docs</a>\n\n', pr, nm);
end

function row(label, text)
    fprintf('  %-13s %s\n', label, text);
end

function s = onOff(b)
    if b
        s = 'on';
    else
        s = 'off';
    end
end

function preview()
    S = requireState();
    tick();
    S = getappdata(groot, 'drpc_state');
    fprintf('\n<strong>Activity</strong>\n%s\n', jsonencode(S.last, 'PrettyPrint', true));
    fprintf('\n<strong>While MATLAB is busy</strong> (sent by the watchdog)\n%s\n', ...
        strrep(jsonencode(S.lastBusy, 'PrettyPrint', true), '1234567890123', '<time the run started>'));
    fprintf('\n<strong>Diagnostics</strong>\n');
    row('Discord', char(Drpc.Bridge.Status));
    row('Updates sent', sprintf('%d', Drpc.Bridge.Updates));
    row('Window', sprintf('%s / %s  "%s"', S.fgKind, S.fgMode, S.fgTitle));
    row('Focus', sprintf('%s  (%s)', S.focus, S.focusClass));
    row('Debugging', onOff(S.debug.active));
    row('MATLAB CPU', sprintf('%.0f%% of one core', double(Drpc.Bridge.Cpu)));
    row('Idle', sprintf('%.0f s', double(Drpc.Bridge.IdleSeconds())));
    row('Bridge', sprintf('v%s, pid %d', char(Drpc.Bridge.BridgeVersion), Drpc.Bridge.Pid));
    if ~isempty(S.error)
        row('Last error', S.error);
    end
    if ~isempty(S.cfgError)
        row('config.json', S.cfgError);
    end
    fprintf('\n');
end
