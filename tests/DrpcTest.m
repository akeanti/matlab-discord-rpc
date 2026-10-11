classdef DrpcTest < matlab.unittest.TestCase
    % Tests for the MATLAB side of drpc. They call the local functions in
    % drpc.m through its hidden test hook and need neither Windows nor
    % Discord, so they run anywhere MATLAB does.
    %
    %   addpath DiscordRPC
    %   runtests tests

    properties
        Root
    end

    methods (TestMethodSetup)
        function makeFolder(tc)
            f = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            tc.Root = f.Folder;
        end
    end

    methods (Static)
        function varargout = call(name, varargin)
            [varargout{1:nargout}] = drpc('__test__', name, varargin{:});
        end
    end

    methods
        function write(tc, txt)
            fid = fopen(fullfile(tc.Root, 'config.json'), 'w');
            fprintf(fid, '%s', txt);
            fclose(fid);
        end

        function txt = read(tc)
            txt = fileread(fullfile(tc.Root, 'config.json'));
        end
    end

    % ------------------------------------------------------------- windows

    methods (Test)
        function simulinkTitles(tc)
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'motor_model - Simulink academic use');
            tc.verifyEqual({m, n}, {'simulink', 'motor_model'});
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'motor_model* - Simulink');
            tc.verifyEqual({m, n}, {'simulink', 'motor_model'}, 'unsaved marker');
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'motor_model/Controller - Simulink');
            tc.verifyEqual({m, n}, {'simulink', 'motor_model'}, 'subsystem');
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'chart/Chart - Stateflow');
            tc.verifyEqual({m, n}, {'simulink', 'chart'});
        end

        function appDesignerTitles(tc)
            [m, n] = DrpcTest.call('classifyTitle', 'matlabwindow', 'App Designer - C:\apps\scope_ui.mlapp*');
            tc.verifyEqual({m, n}, {'app', 'scope_ui.mlapp'});
            [m, n] = DrpcTest.call('classifyTitle', 'matlabwindow', 'App Designer');
            tc.verifyEqual({m, n}, {'app', ''});
        end

        function figureTitles(tc)
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'Figure 2: Bode Plot');
            tc.verifyEqual({m, n}, {'plot', 'Figure 2: Bode Plot'});
            tc.verifyEqual(DrpcTest.call('classifyTitle', 'matlab', 'Figure 1'), 'plot');
            tc.verifyEqual(DrpcTest.call('classifyTitle', 'matlabwindow', 'UI Figure'), 'plot');
        end

        function desktopTitle(tc)
            [m, n] = DrpcTest.call('classifyTitle', 'matlab', 'MATLAB R2024a - academic use');
            tc.verifyEqual({m, n}, {'main', ''});
        end
    end

    % ------------------------------------------------------------- files

    methods (Test)
        function fileKinds(tc)
            k = @(ext, txt) DrpcTest.call('fileKind', ext, txt);
            tc.verifyEqual(k('.m', sprintf('%% help\n%% more\nfunction y = f(x)\n')), 'Function');
            tc.verifyEqual(k('.m', sprintf('  classdef Foo < handle\n')), 'Class');
            tc.verifyEqual(k('.m', sprintf('x = 1;\nfunction y = f(x)\n')), 'Script', ...
                'a script with local functions is still a script');
            tc.verifyEqual(k('.m', ''), 'Script');
            tc.verifyEqual(k('.mlx', ''), 'Live Script');
            tc.verifyEqual(k('.cpp', ''), 'C/C++ file');
            tc.verifyEqual(k('.json', ''), 'JSON file');
        end

        function labelsHideNames(tc)
            ed = struct('file', 'pid.m', 'kind', 'Function');
            tc.verifyEqual(DrpcTest.call('fileLabel', ed, true), 'pid.m');
            tc.verifyEqual(DrpcTest.call('fileLabel', ed, false), 'a function');
            ed = struct('file', 'notes.txt', 'kind', 'Text file');
            tc.verifyEqual(DrpcTest.call('fileLabel', ed, false), 'a file');
            ed = struct('file', '', 'kind', '');
            tc.verifyEqual(DrpcTest.call('fileLabel', ed, true), '');
        end

        function hiddenFolders(tc)
            hidden = @(p, paths) DrpcTest.call('isHidden', p, paths);
            tc.verifyTrue(hidden({'internship'}, {'C:\work\Internship\src', ''}));
            tc.verifyFalse(hidden({'Internship'}, {'C:\lab3', 'C:\lab3\sub'}));
            tc.verifyFalse(hidden({'  '}, {'C:\lab3'}), 'blank entries hide nothing');
        end
    end

    % ------------------------------------------------------------- payload

    methods (Test)
        function clipFitsDiscord(tc)
            tc.verifyEqual(DrpcTest.call('clip', 'a'), '', 'Discord needs 2 characters');
            tc.verifyEqual(DrpcTest.call('clip', '  ok  '), 'ok');
            s = DrpcTest.call('clip', repmat('x', 1, 300));
            tc.verifyLength(s, 128);
            tc.verifyEqual(s(end), char(8230));
        end

        function buttonsAreChecked(tc)
            raw = {struct('label', 'GitHub', 'url', 'https://github.com/x'), ...
                struct('label', 'Bad', 'url', 'ftp://x'), ...
                struct('label', repmat('L', 1, 40), 'url', 'https://a.b'), ...
                struct('label', 'Third', 'url', 'https://c.d')};
            b = DrpcTest.call('buttonList', raw);
            tc.verifyLength(b, 2, 'at most two, invalid ones skipped');
            tc.verifyEqual(b{1}.label, 'GitHub');
            tc.verifyLength(b{2}.label, 32);
        end

        function activityShape(tc)
            c = DrpcTest.call('defaultConfig');
            c.member_list = 'details';
            c.buttons = {struct('label', 'GitHub', 'url', 'https://github.com/x')};
            S = struct('release', 'R2024a');
            a = DrpcTest.call('makeActivity', c, S, 'Editing pid.m', 'Function', 'editing', '', int64(5));
            tc.verifyEqual(a.details, 'Editing pid.m');
            tc.verifyEqual(a.state, 'Function');
            tc.verifyEqual(a.assets.large_text, 'MATLAB R2024a');
            tc.verifyEqual(a.assets.small_text, 'Editing', 'falls back to the icon name');
            tc.verifyEqual(a.status_display_type, int32(2));
            tc.verifyEqual(a.timestamps.start, int64(5));
            tc.verifyTrue(contains(jsonencode(a), '"buttons":[{"label":"GitHub"'), 'buttons go out as an array');

            c.images.editing = '';
            a = DrpcTest.call('makeActivity', c, S, 'Editing pid.m', '', 'editing', '', int64(5));
            tc.verifyFalse(isfield(a.assets, 'small_image'), '"" hides the icon');
            tc.verifyFalse(isfield(a, 'state'));
        end
    end

    % ------------------------------------------------------------- config

    methods (Test)
        function starterConfigIsWritten(tc)
            [c, ~, problem] = DrpcTest.call('readConfig', tc.Root);
            tc.verifyEmpty(problem);
            tc.verifyEqual(c, DrpcTest.call('defaultConfig'));
            u = jsondecode(tc.read());
            tc.verifyFalse(isfield(u, 'client_id'), 'defaults that may change stay out of the file');
            tc.verifyFalse(isfield(u, 'images'));
            tc.verifyTrue(isfield(u, 'show_names') && isfield(u, 'hidden_folders'));
        end

        function partialConfigMerges(tc)
            tc.write('{"show_names": false, "hidden_folders": "Exam", "idle_minutes": "ten", "images": {"idle": ""}, "nonsense": 1}');
            c = DrpcTest.call('readConfig', tc.Root);
            def = DrpcTest.call('defaultConfig');
            tc.verifyFalse(c.show_names);
            tc.verifyEqual(c.hidden_folders, {'Exam'});
            tc.verifyEqual(c.idle_minutes, def.idle_minutes, 'wrong type falls back');
            tc.verifyEqual(c.images.idle, '');
            tc.verifyEqual(c.images.editing, def.images.editing);
            tc.verifyFalse(isfield(c, 'nonsense'));
        end

        function brokenConfigKeepsCurrentSettings(tc)
            tc.write('{"show_names": false,}');
            current = DrpcTest.call('defaultConfig');
            current.show_names = false;
            current.hidden_folders = {'Secret'};
            [c, ~, problem] = DrpcTest.call('readConfig', tc.Root, current);
            tc.verifyNotEmpty(problem);
            tc.verifyEqual(c, current, 'a typo must not turn names back on');

            tc.write('[1, 2]');
            [c, ~, problem] = DrpcTest.call('readConfig', tc.Root, current);
            tc.verifyNotEmpty(problem);
            tc.verifyEqual(c, current);
        end

        function numericClientIdIsRejected(tc)
            tc.write('{"client_id": 1558853253620564039}');
            c = tc.verifyWarning(@() DrpcTest.call('readConfig', tc.Root), 'drpc:config');
            tc.verifyEqual(c.client_id, DrpcTest.call('defaultConfig').client_id);
        end

        function setValueKeepsTheRestOfTheFile(tc)
            txt = sprintf('{\n    "show_names": true,\n    "hidden_folders": ["Internship"],\n    "idle_minutes": 5\n}\n');
            tc.write(txt);
            DrpcTest.call('setConfigValue', tc.Root, 'show_names', false);
            tc.verifyEqual(tc.read(), strrep(txt, '"show_names": true', '"show_names": false'));
        end

        function setValueAddsAMissingKey(tc)
            tc.write('{"idle_minutes": 5}');
            DrpcTest.call('setConfigValue', tc.Root, 'show_names', false);
            u = jsondecode(tc.read());
            tc.verifyEqual(u.show_names, false);
            tc.verifyEqual(u.idle_minutes, 5);

            tc.write('{}');
            DrpcTest.call('setConfigValue', tc.Root, 'show_names', true);
            u = jsondecode(tc.read());
            tc.verifyEqual(u.show_names, true);
        end

        function setValueRefusesABrokenFile(tc)
            tc.write('{"show_names": tru}');
            tc.verifyError(@() DrpcTest.call('setConfigValue', tc.Root, 'show_names', false), 'drpc:config');
            tc.verifyEqual(tc.read(), '{"show_names": tru}', 'the file is left alone');
        end

        function stampSeesSameSecondSaves(tc)
            tc.write('{"a": 1}');
            s1 = DrpcTest.call('fileStamp', fullfile(tc.Root, 'config.json'));
            tc.write('{"a": 10}');
            s2 = DrpcTest.call('fileStamp', fullfile(tc.Root, 'config.json'));
            tc.verifyNotEqual(s1, s2);
            tc.verifyEmpty(DrpcTest.call('fileStamp', fullfile(tc.Root, 'nope.json')));
        end
    end

    % ------------------------------------------------------------- startup.m

    methods (Test)
        function startupBlockOnEmptyFile(tc)
            txt = DrpcTest.call('withStartupBlock', '');
            tc.verifyTrue(startsWith(txt, '% >>> MATLAB Discord RPC >>>'));
            tc.verifyTrue(contains(txt, 'drpc autostart'));
        end

        function startupBlockKeepsYourCode(tc)
            mine = sprintf('format compact\ncd C:\\work\n');
            once = DrpcTest.call('withStartupBlock', mine);
            tc.verifyTrue(startsWith(once, mine));
            twice = DrpcTest.call('withStartupBlock', once);
            tc.verifyEqual(twice, once, 'setup twice adds one block');
            back = regexprep(DrpcTest.call('removeStartupBlock', once), '\s+$', '');
            tc.verifyEqual(back, strtrim(mine));
        end

        function startupBlockInTheMiddle(tc)
            txt = [sprintf('a = 1;\n') DrpcTest.call('withStartupBlock', '') sprintf('b = 2;\n')];
            out = DrpcTest.call('removeStartupBlock', txt);
            tc.verifyFalse(contains(out, 'Discord'));
            tc.verifyTrue(contains(out, 'a = 1;') && contains(out, 'b = 2;'));
        end
    end

    % ------------------------------------------------------------- update

    methods (Test)
        function versionOrder(tc)
            newer = @(a, b) DrpcTest.call('isNewer', a, b);
            tc.verifyTrue(newer('1.1.0', '1.0.0'));
            tc.verifyTrue(newer('1.10.0', '1.9.2'), 'numbers, not text');
            tc.verifyTrue(newer('2', '1.9.9'));
            tc.verifyFalse(newer('1.0.0', '1.0.0'));
            tc.verifyFalse(newer('1.0', '1.0.0'));
            tc.verifyFalse(newer('0.9.0', '1.0.0'));
        end

        function noAutoStartInBatch(tc)
            % this suite itself runs in -batch in CI
            tc.assumeTrue(batchStartupOptionUsed, 'only meaningful in -batch');
            tc.verifyFalse(DrpcTest.call('mayAutoStart'));
            tc.verifyFalse(DrpcTest.call('hasDesktop'));
        end
    end
end
