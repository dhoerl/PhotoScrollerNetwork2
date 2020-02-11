# PhotoScrollerNetwork2
Demo app that uses the new PhotoScrollerSwiftPackage, updated PhotoScrollerNetwork code

The revised PhotoScrollerNetwork code now offers a NSOuputStream interface, that makes it easy to drive
with a file based NSInputStream or a network-based one (both provided in this project).

This app uses SwiftUI and Combine too. Look at the unit tests for how to use traditional input streams to drive the image creation process.

Requires the use of the PhotoScrollPackage.

Updates:

Feb 11, 2020: this is now functional for both file based and web based assets. Notice that even for the largest file, Space6, the decoding difference between a 
  local file and a network asset are barely perceptable - this due to the parallel image decoding.
  
