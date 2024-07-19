<#
.SYNOPSIS
    VHSify.ps1 - Converts a specified video file into a VHS-like format with a resolution of 480p.

.DESCRIPTION
    This script processes an input video file to simulate the visual aesthetics of VHS tapes. It accomplishes this by:
    - Scaling the video to a height of 480 pixels while maintaining its aspect ratio
    - Cropping the scaled video to a width of 640 pixels (standard 480p resolution)
    - Extracting the Y (luminance), U, and V (chrominance) planes
    - Resampling the U and V planes to represent lower chroma resolutions typically found in VHS tapes
    - Merging the Y, U, and V planes back together to form the final video
    - Retaining the original audio track in the final video file
    
.PARAMETER inputFile
    Specifies the path to the input video file to be processed.

.OUTPUTS
    Generates a new video file in the same directory as the input file, with the suffix "-VHS" appended to the base name of the input file.

.EXAMPLE
    .\VHSify.ps1 -inputFile "C:\Videos\example.mp4"
    
    This will generate a VHS-style video from "example.mp4" and save it as "example-VHS.mp4" in the same directory.

.NOTES
    This script requires FFmpeg to be installed and accessible from the command line.
#>

param (
    [string]$inputFile
)

# Define a temporary directory (optional)
$tempDir = $env:TEMP  # Change this to your desired temp directory

# Extract the bitrate of the original video
$bitrate = (ffmpeg -i $inputFile 2>&1 | Select-String -Pattern "bitrate: \d+ kb/s").Matches.Value -replace "bitrate: " -replace " kb/s"

Write-Host "Scaling video to 480p..." -ForegroundColor Yellow
# First, scale the input file to a height of 480 pixels while maintaining the aspect ratio
$blurSigma = 1
ffmpeg -loglevel error -stats -i $inputFile -vf "scale=-1:480,pad=ceil(iw/2)*2:ceil(ih/2)*2,gblur=sigma=$blurSigma" -b:v $bitrate"k" -c:a copy "$tempDir\temp_scaled.mp4"

Write-Host "Cropping video to SD..." -ForegroundColor Yellow
# Then, crop the scaled video to a width of 332 pixels while keeping the height unchanged
ffmpeg -loglevel error -stats -i "$tempDir\temp_scaled.mp4" -vf "crop=640:480" -b:v $bitrate"k" -c:a copy "$tempDir\temp_cropped.mp4"

Write-Host "Extracting Luminance and Chrominance information..." -ForegroundColor Yellow
# Extract Y, U, and V planes from the cropped video
ffmpeg -loglevel error -stats -i "$tempDir\temp_cropped.mp4" -vf "extractplanes=y,setsar=1" -b:v $bitrate"k" "$tempDir\temp_y_plane.mp4"
ffmpeg -loglevel error -stats -i "$tempDir\temp_cropped.mp4" -vf "extractplanes=u" -b:v $bitrate"k" "$tempDir\temp_u_plane.mp4"
ffmpeg -loglevel error -stats -i "$tempDir\temp_cropped.mp4" -vf "extractplanes=v" -b:v $bitrate"k" "$tempDir\temp_v_plane.mp4"

Write-Host "Resampling Chroma..." -ForegroundColor Yellow
# Resample and resize U and V planes
ffmpeg -loglevel error -stats -i "$tempDir\temp_u_plane.mp4" -vf "scale=80:240:flags=bilinear,setsar=1" -b:v $bitrate"k" "$tempDir\temp_u_resampled.mp4"
ffmpeg -loglevel error -stats -i "$tempDir\temp_v_plane.mp4" -vf "scale=80:240:flags=bilinear,setsar=1" -b:v $bitrate"k" "$tempDir\temp_v_resampled.mp4"

ffmpeg -loglevel error -stats -i "$tempDir\temp_u_resampled.mp4" -vf "scale=320:240:flags=bilinear,setsar=1" -b:v $bitrate"k" "$tempDir\temp_u_resized.mp4"
ffmpeg -loglevel error -stats -i "$tempDir\temp_v_resampled.mp4" -vf "scale=320:240:flags=bilinear,setsar=1" -b:v $bitrate"k" "$tempDir\temp_v_resized.mp4"

Write-Host "Combining video..." -ForegroundColor Yellow
# Merge Y, U, and V planes with audio
ffmpeg -loglevel error -stats -i "$tempDir\temp_y_plane.mp4" -i "$tempDir\temp_u_resized.mp4" -i "$tempDir\temp_v_resized.mp4" -i "$tempDir\temp_cropped.mp4" -b:v $bitrate"k" -filter_complex "[0:v][1:v][2:v]mergeplanes=0x001020:yuv420p[out]" -map "[out]" -map 3:a -c:a copy "$((Get-Item $inputFile).BaseName)-VHS.mp4"

# Clean up temporary files
Remove-Item "$tempDir\temp_*"
