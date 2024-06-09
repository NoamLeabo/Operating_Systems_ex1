#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

// global list of commands
char historyOfCmds[100][100] = {0};
// number of commands
int numOfCmd = 0;

// function that prints the current working directory
void pwd()
{
    // first a buffer to store the current working directory
    char cwd[1024];
    // now get the current working directory
    if (getcwd(cwd, sizeof(cwd)) != NULL)
    {
        // we print the current working directory if is valid
        printf("%s\n", cwd);
    }
    else
    {
        // otherwise we print an error message if it is not valid
        perror("getcwd() error");
    }
}

// function that changes the current working directory
void cd(const char *path)
{
    // we try to change the current working directory to the new directory
    if (chdir(path) == 0)
    {
        // everything is fine
    }
    else
    {
        // print an error message if an error occurred
        perror("chdir() error");
    }
}

// function that prints the history of commands
void history()
{
    // we simply print the history of commands
    for (int i = 0; i < numOfCmd; i++)
    {
        printf("%s\n", historyOfCmds[i]);
    }
}

// function that adds a command to the history of commands
void addCmdToHistory(char *cmd)
{
    // we add the entire command to the history of commands
    strcpy(historyOfCmds[numOfCmd], cmd);
    // we increment the number of commands
    numOfCmd++;
}

// function that adds a path to the PATH environment variable
void addToEnvPATH(char path[100])
{
    // first we store the current value of the PATH env var
    char *currentPath = getenv("PATH");
    // then we store the new value of the PATH env var
    char newPath[1024];
    // we copy the current value to the new var
    strcpy(newPath, currentPath);
    // concatenate the new path with a separator and the new value
    strcat(newPath, ":");
    strcat(newPath, path);
    // set the new full value of the PATH-env variable
    setenv("PATH", newPath, 1);
}

int main(int argc, char *argv[])
{
    // we add the paths to the PATH environment variable if those are provided
    if (argc > 1)
    {
        for (int i = 1; i < argc; i++)
        {
            // we send each argument to be added to the PATH-env var
            addToEnvPATH(argv[i]);
        }
    }

    // a buffer to store the command
    char command[100];
    // a variable to store the status of the child process
    int status;
    // a loop to keep the shell on running
    while (1)
    {
        // we print the shell prompt
        printf("$ ");
        fflush(stdout);
        // we scan the command from the user
        if (fgets(command, sizeof(command), stdin) == NULL)
        {
            perror("fgets() error");
            continue;
        }
        // remove the trailing newline character
        command[strcspn(command, "\n")] = 0;
        // we check if the command is exit
        if (strcmp(command, "exit") == 0)
        {
            // exit the shell
            exit(0);
        }
        // we check if the command is pwd
        else if (strcmp(command, "pwd") == 0)
        {
            // we first add the command to the history of commands
            addCmdToHistory(command);
            // then we execute the command
            pwd();
        }
        // we check if the command is cd
        else if (strncmp(command, "cd ", 3) == 0)
        {
            // we first add the command to the history of commands
            addCmdToHistory(command);
            // extract the path from the command
            char *path = command + 3;
            // then we execute the command
            cd(path);
        }
        // we check if the command is history
        else if (strcmp(command, "history") == 0)
        {
            // we first add the command to the history of commands
            addCmdToHistory(command);
            // then we execute the command
            history();
        }
        // if the command is not one of the implementation required commands
        else
        {
            // Add a buffer for reading the full command line with arguments
            char fullCommand[256];
            char *args[10];
            int arg_count = 0;

            // Copy the initial command to the fullCommand buffer
            strcpy(fullCommand, command);

            // Tokenize the input command
            char *token = strtok(fullCommand, " \n");
            while (token != NULL && arg_count < 10)
            {
                args[arg_count++] = token;
                token = strtok(NULL, " \n");
            }
            args[arg_count] = NULL; // Null-terminate the array of arguments

            pid_t pid = fork();
            if (pid == 0)
            {
                execvp(args[0], args); // Use execvp to pass the arguments
                perror("exec failed"); 
                exit(1);
            }
            else if (pid < 0)
            {
                // print an error message if the fork failed
                perror("fork() error");
                exit(1);
            }
            else
            {
                // we add the command to the history of commands
                addCmdToHistory(command);
                wait(&status);
            }
        }
    }
    return 0;
}
