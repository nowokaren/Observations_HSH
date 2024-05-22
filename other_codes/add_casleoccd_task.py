from pyraf import iraf

# Replace '/path/to/iraf/tasks/' with the actual path to the directory containing casleoccd.cl
task_directory = 'casleoccd'

# Add the task directory to IRAF's search path
iraf.task('cd casleoccd', logfile='iraf.log')


