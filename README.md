# Specgen Repositories

The Specgen repository is now split into two repositories:
	
1. **nsip/specgen-sourcecode** - C# project for the console application that generates the Specification artifacts.
2. **nsip/specgen_input** - Files used as input and configuration of the Specgen application. The source code expects this to be in a folder called bin/Debug/dist/Specification within the C# source code folder. Generated output files are also placed within the directory tree of this folder in a folder called out. Thus, the files in this repository are nested within the directory tree of the C# project folder. 
	
### How to acquire the two repositories, nest them, and maintain them separately using Github. 

Using the command line (I am using Git Bash on Windows):

1. Navigate to the directory in which you want to place the project.
2. run: 
	`git clone git@github.com:nsip/specgen-sourcecode.git <local directory name (optional)>`  
	or for https  
	`git clone https://github.com/nsip/specgen-sourcecode.git <local directory name (optional)>`
3. Navigate into the C# project folder just created: 
	`cd <local directory name>/GenerateSpecTool_5`
4. Navigate to the folder where the specgen_input files will be:  
	`cd bin/Debug/dist`
5. The folder created by git clone must be named Specification. run:  
	`git clone git@github.com:nsip/specgen_input.git Specification`  
	or for https  
	`git clone https://github.com/nsip/specgen_input.git Specification` 

The specgen-source code repository has an entry in .gitignore that will cause the Specification directory to be ignored. This enables separate pushes to each repository. You can verify this by navigating to the specgen-sourcecode local directory and running "git remote -v" and then and then navigating to the Specification directory and running the same command. You will see different remote repositories. 

### How to run the compiled version of Specgen.

1. Copy the bin/Debug/dist folder (should we make an installer?) to a place on the Windows machine. This includes parts of both repositories. 
2. Run `GenerateSpec.exe` with a parameter as shown in 00Build.cmd or run any of the other .cmd files in the dist folder. 