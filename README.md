# SCOOP
Demonstration of SCOOP (Simple Concurrent Object-Oriented Programming) usage in Eiffel
## Structure
* `example`: ready-to-use simple examples that can be compiled and run to see how certain functionality can be achieved in a SCOOP-driven system
* `library`: reusable code that can be used unmodified in other applications
## How to use?
1. Download the source code, e.g.
```
wget -c https://github.com/kwaxer/scoop/archive/master.zip
unzip master.zip
```
2. Compile and run an example, e.g.
```
cd scoop-master/example/launcher
ec -freeze -config launcher.ecf -c_compile
EIFGENs/launcher/W_code/launcher
```
3. Use the library in your project by adding a reference to `scoop-master/library/scoop.ecf`.
4. Include the license and copyright notice in your project.
## System requirements
The software was tested with [EiffelStudio](https://www.eiffel.org/downloads) 19.05 (stable) and 19.12 (beta) releases.
