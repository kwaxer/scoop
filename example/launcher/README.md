# Command launcher example
## How to build and run?
```
ec -freeze -config launcher.ecf -c_compile
EIFGENs/launcher/W_code/launcher
```
## Window layout
The application opens a window with the following areas:
Area | Usage | Description
-----|-------|------------
Top left | Command line | An input field to enter commands for execution
Middle left | Output | Output of all commands goes here. Normal output is shown in black. Error output is shown in red.
Right | Running commands | The list of currently running commands. The list automatically removes command lines of terminated commands.
Bottom | Status | Result of most recent command execution: whether a program has started successfully, whether it has terminated and with which code.
## How to use?
Type a command in the command line field and press _Enter_. While one command runs, another one could be executed at the same time. Output of both commands will be redirected to the same output area. Several commands can be executed simultaneously.
For example, on Windows, you can run the following sequence of commands:
```
for /l %i in (1,1,1024) do @(timeout 1| echo +%i)
for /l %i in (1,1,1024) do @(timeout 2| echo -%i)
dir
complete_nonsense
```
The first two loops print sequences "+1, +2, +3, ...", and "-1, -2, -3, ..." respectively with some delay between numbers, the third command displays the current directory contents and the last one reports an error in red.
