% INSTALL  Install or update Discord Rich Presence for MATLAB.
%
%   Run this file from the downloaded folder:
%       install
%
%   or straight from GitHub, pasted into the Command Window:
%       unzip("https://github.com/akeanti/matlab-discord-rpc/archive/refs/heads/main.zip", tempdir); run(fullfile(tempdir, "matlab-discord-rpc-main", "install.m"))
%
%   It copies the DiscordRPC folder into your MATLAB user folder, makes it
%   start with MATLAB, and turns it on. Your config.json is kept on update.

drpcInstall(fileparts(mfilename('fullpath')));

function drpcInstall(here)
    if ~ispc
        error('drpc:platform', 'Discord RPC for MATLAB runs on Windows.');
    end
    try
        tooOld = isMATLABReleaseOlderThan("R2021a");
    catch
        tooOld = true;
    end
    if tooOld
        warning('drpc:release', 'drpc needs MATLAB R2021a or newer.');
    end

    src = fullfile(here, 'DiscordRPC');
    base = strtok(char(userpath), pathsep);
    if isempty(base)
        base = fullfile(getenv('USERPROFILE'), 'Documents', 'MATLAB');
    end
    dest = fullfile(base, 'DiscordRPC');

    % stop a running copy before its files are replaced
    if ~isempty(timerfindall('Name', 'DiscordRPC')) && exist('drpc', 'file') == 2
        evalc('drpc stop');
    end

    if ~isfolder(dest)
        mkdir(dest);
    end
    if ~strcmpi(src, dest)
        copyfile(fullfile(src, 'drpc.m'), fullfile(dest, 'drpc.m'), 'f');
        copyfile(fullfile(src, 'DrpcBridge.cs'), fullfile(dest, 'DrpcBridge.cs'), 'f');
    end
    addpath(dest);
    rehash path

    drpc setup
    drpc start
    fprintf('\nInstalled in %s\nType <a href="matlab:drpc">drpc</a> to see what Discord shows.\n\n', dest);
end
