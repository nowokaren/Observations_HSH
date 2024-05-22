import os
from pyraf import iraf

# Set up IRAF parameters
iraf.gemini()
iraf.gemini.gemtools()
iraf.gemini.gnirs()
iraf.task("casleoccd/casleoccd.py")

# Set up IRAF display parameters
#iraf.set(stdimage='imt1024', StdoutGraf='no')


def casleoccd_hsh(image_list, master_bias=None, master_flat=None, master_dark=None):
    instrumento = 'HSH-STL'  # Instrumento utilizado (Cámara)
    binning = 1  # Factor de binning (X,Y)
    redfoc = 'no'  # ¿Se usó reductor focal? (solo JS-Roper)
    ganron = 'no'  # ¿Calcula ganancia y ruido de lectura?
    sethead = 'no'  # ¿Agrega/actualiza headers (EPADU y RDNOISE)?
    masterbias = 'yes' if master_bias is None else master_bias  # ¿Genera master BIAS? (Zero)
    masterflat = 'yes' if master_flat is None else master_flat  # ¿Genera master FLAT? (FlatX)
    masterdark = 'yes' if master_dark is None else master_dark  # ¿Genera master DARK? (Dark)
    borracal = 'no'  # ¿Borra calibraciones originales?
    procesa = 'yes'  # ¿Procesa todas las imágenes?
    ovscinter = 'no'  # ¿Ajusta overscan en forma interactiva? (solo JS Roper y Tek)
    oscuridad = 'yes'  # ¿Corrige por dark? (solo HSH-STL)
    cosmicos = 'no' # ¿Corrige por rayos cósmicos (lacos-im)?
    epadu = 1.0  # Valor de ganancia calculado (e-/adu)
    rdnoise = 0.0  # Valor de ruido de lectura calculado (e-)

    # Definir las rutas a los archivos de configuración
    base = 'Settings/'  # Directorio base donde se encuentran los archivos de configuración


    # Llamada a la tarea de IRAF casleoccd
    iraf.casleoccd(instrumento=instrumento, binning=binning, redfoc=redfoc, ganron=ganron, sethead=sethead, masterbias=masterbias, masterflat=masterflat, masterdark=masterdark, borracal=borracal, procesa=procesa, ovscinter=ovscinter, oscuridad=oscuridad, cosmicos=cosmicos, epadu=epadu, rdnoise=rdnoise, listbias=image_list['bias'], listflat=image_list['flat'], listdark=image_list['dark'], listima=image_list['sci'], flatcielo='no', flatHWP='no', base=base, rfilJS=2, rfilHSH='ext')


                  

#filt = "i"

nights = os.listdir("data_hsh/")
night = nights[12]
print(night)
night_images = os.listdir(f"data_hsh/{night}")
images_lists = {}


images_lists["bias"] = " ".join([f"data_hsh/{night}/"+file for file in night_images if ("bias" in file) and (".fit" in file)])
images_lists["flat"] = " ".join([f"data_hsh/{night}/"+file for file in night_images if ("flat" in file) and (".fit" in file)])
images_lists["dark"] = " ".join([f"data_hsh/{night}/"+file for file in night_images if ("dark" in file) and (".fit" in file)])
images_lists["sci"] = " ".join([f"data_hsh/{night}/"+file for file in night_images if ("OGLE" in file) and (".fit" in file)])

'''

images_lists["bias"] = [f"data_hsh/{night}/"+file for file in night_images if ("bias" in file) and (".fit" in file)]
images_lists["flat"] = [f"data_hsh/{night}/"+file for file in night_images if ("flat" in file) and (".fit" in file)]
images_lists["dark"] = [f"data_hsh/{night}/"+file for file in night_images if ("dark" in file) and (".fit" in file)]
images_lists["sci"] = [f"data_hsh/{night}/"+file for file in night_images if ("OGLE" in file) and (".fit" in file)]


images_files = {}
for kind, file_list in images_lists.items():
    file_path = f"data_hsh/{night}/{kind}list.txt"
    file_content = '\n'.join(file_list)
    with open(file_path, 'w') as f:
        f.write(file_content)
    images_files[kind] = file_path
    print(kind + "    " + str(len(file_list)))
'''
	

if images_lists["sci"] != []:
	# Se generan las correcciones de rayos cósmicos si no existen previamente
	#if not os.path.isfile('cr_image1.fits'):
	#    lacos_im(['image1.fits'])
	#images_list = os.listdir(f"nights_images/{nights[2]}") 

	casleoccd_hsh(images_lists)
else:
	print("No OGLE images in "+night)

