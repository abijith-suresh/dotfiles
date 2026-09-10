# Pi setup

The Pi configuration is managed by the pi Stow package. Its source lives in
configs/pi/.pi/agent, which is deployed to ~/.pi/agent.

The package contains:

- the ask-user tool extension
- the clarify extension
- the in-process subagent extension
- the subagents skill
- the Catppuccin Mocha theme
- TypeScript source and locked npm dependencies

install/apps/agents/pi.sh installs Pi when needed. After Stow deploys the
managed files, pi-setup.sh runs npm ci --ignore-scripts in ~/.pi/agent and its
subagent extension. The dependencies stay in the user directory instead of
the source tree. Authentication, sessions, logs, and other generated state
also remain outside Git. Pi extensions run with the permissions of the Pi
process, so changes to these files should be reviewed like executable code.

The package currently targets Pi 0.83.0, the API version used by the checked-in
npm lockfiles. Update the Pi CLI and package dependencies together, then run:

    npm run check
    npm run format:check
