# Vesuvius Download Scripts Windows 10
A powershell script to quickly download data from the vesuvius scroll challenge

## Setup
To use the script you will need to accept the Vesuvius Scroll Prize Data license: https://scrollprize.org/data
Once you have accepted you will be informed of the username and password and you will need to replace $user and $password with those values
Then simply place the script in the folder you would like the .tif files to be downloaded to and run the script with an administrator powershell window. I recommend using the latest script version as it will have the most features.

## Usecase
This script is for windows users who want to download different ranges of the scroll quickly, with minimal setup. The script has no dependencies that a windows 10 machine shouldnt already have, and just neeeds to be placed in the target folder, have the parameters edited to the desired range, and ran with powershell. It can also be used to download the entire scroll, but rclone as suggested on the download doc page may be better for this usecase as it has the ability to retry failed downloads, though I never ran into that issue testing this script. rclone does require you to install it though. 

## Parameters
**$ranges** specifies the range of .tif files you would like to download. I have set it to a few from the front, a large chunk in the middle, and a few from the end of the scroll. This can specify either one range, or a single file by setting the start equal to the end, or multiple ranges. The number corresponds to the tif filename.

**$null = $runspacePool.SetMaxRunspaces(X)** specifies the maximum number of concurrent runspaces, the optimal value will depend on yout internet connection and system resources. I recommend testing the script on batches of 50-100 files to get representative performance with a variety of values. I found 200 works well for me but I have very fast fibreoptic internet and a fairly fast computer, writing to an SSD, so lower values are probably optimal. Setting the value too high can result in system resource contention and longer download times. Testing 10, 50, 100, 200 would be a good start to see how it effects performance.

**$overwriteExistingFiles** prevents the script from redownloading files that already exist in the folder. You can set it to true if you want to redownload, because some of the data is corrupted or something like that.

**$outputFolder** specifies where the files should be downloaded to, I have the default set to a folder adjacent to the script called fullScrollData, it will create the folder if it doesnt already exist.

**$url** points to the folder on the download server of where to download from. By default it points to Full Scroll 1, you can change the path to point to the other full scroll, or the fragments and the script will work to download those files as well.

## Useful Alternative Usecase
Some users have reported that they are missing some frames after downloading with rclone, with $overwriteExistingFiles set to false (default value) you can use this script to run over the range with those few missing frames to quickly download them. Also if some frames are corrupted, you can delete them and run the script like this as well.

## Performance
Since the script downloads in parallel using a pool, it is very efficent in optimal conditions:
![image](https://user-images.githubusercontent.com/49734270/233860549-3ede5b8c-227e-4831-b14c-397ac71fbba3.png)<br>
With few things running and a 3Gb/s fibreoptic download connection I was able to download 120MB .tif files in a bit over 1 second each.
Compared to >60s per file from the sequential wget method presented in the download documentation, this represents a large improvement.
The server they are hosted on is also very fast, but high demand could slow the downloads down. Essentially the script shouldnt be a bottleneck.
It may take longer to download just a handful of files as its not taking advantage of the parallelism (20-30 seconds each in my experience)



