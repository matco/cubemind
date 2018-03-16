# Cubemind
A Mastermind-like game for the [Futurocube](http://www.futurocube.com).

## How to install on your cube
1. Download, install and run the [RFCSuite](http://www.futurocube.com/support).
2. Download the latest release of **Cubemind** on the application [release](https://github.com/matco/cubemind/releases) page.
3. Drag and drop the file ```cubemind.amx``` in your cube.
4. Apply changes.

## How to play
1. When the game starts, the cube will choose a secret code.
2. Choose a side to make your first guess: the blue dot serves as a reference for the orientation of the secret code.
3. Orient the cube to select the corner you want to edit.
4. Change the color of the selected corner by tapping the side of the cube.
5. To check your guess, double tap the top of the cube.
6. A red light means that one of your dot is correct in both color and position, a white one means one of your dot has the right color in the wrong position.
7. Find the secret code before you fill the cube.

## How to debug on your cube
1. Download, install and run the [RFCSuite](http://www.futurocube.com/support).
2. Open SDK mode.
3. Select the script ```cubemind.p```, and press "Compile and Upload to FLASH" (the game can not been run from RAM because it uses too much memory).
4. In the console, type ```prunf```.
