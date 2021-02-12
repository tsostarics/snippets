import pandas as pd
import csv
import os
import re

# Double check what your working directory is, make sure it's the folder with 
# all of the pitch tier files you want to process
os.getcwd()
os.chdir("D:\\Experiments\\qp_exp_1\\sound") # Change directory here if needed

# Compile some regular expressions to use
re_ext = re.compile(r'.PitchTier$')           # Checks for pitchtier files
re_points = re.compile(r'    (value|number)') # Checks for value/number lines
re_num = re.compile(r'\d+\.\d+')              # Gets number values

# Get all the pitchtier files, it's okay if you have other files here
filenames = [f for f in os.listdir(os.getcwd()) if '.PitchTier' in f]

# Empty list to hold our data, along with a row id for unique row identifiers
buffer = []
rowid =0

# Look through all the files
for file in filenames:
  # Read in text
  file_lines = open(file, 'r').readlines()
  # Get only the lines with the pitch points
  pitch_points = [line for line in file_lines if re_points.search(line) is not None]
  
  # Declare variables to extract values into
  # Each pitch point has a timestamp (number = ~~) 
  # and pitch value in Hz (value = ~~)
  timestamp = None
  hertz = None
  i = 0

  for entry in pitch_points:
    # If we have a pair of values that make up a pitch point, add a row to our
    # buffer with the filename, the point number, the timestamp, and the Hz value
    # Then reset the timestamp and hertz variables for subsequent iterations
    # basically this lets us "go by 2" lines
    if timestamp is not None and hertz is not None:
      # print(file)
      buffer.append({'row':rowid, 'filename': file, 'point_num': i, 'time':timestamp, 'pitch':hertz})
      i += 1
      rowid += 1
      timestamp = None
      hertz = None
    elif 'number' in entry: # If it's a time value
      # Extract the number string, then convert to numeric
      # they're all long decimal numbers so float() is fine
      timestamp = float(re_num.search(entry).group(0))
    elif 'value' in entry: # If it's a Hz value
      hertz = float(re_num.search(entry).group(0))

# Convert list to dataframe, then save as csv file
pd.DataFrame(buffer).to_csv(os.getcwd()+"\\pitchtiers_processed.csv", index=False)
