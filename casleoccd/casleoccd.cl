procedure casleoccd(instrumento,binning)
# Tarea para procesar im�genes directas con CCDs del CASLEO
# Instrumento = JS-Roper: Roper-2048 (JS+directo)
#               JS-Tek: Tek-1024 (JS+CasPol)
#               HSH-STL: STL-1001E (HSH)
# Autor: S. Cellone - L. Zibecchi - L. Mammana (junio 2020)
# dic/2021: zerocombine.nhigh=2 para Tek-1024
# ago/2022: 2da rueda de filtros para TJS y HSH

#char telescopio{'JS', prompt='Telescopio', enum='JS|HSH'}
char instrumento{'JS-Roper', prompt='Instrumento', enum='JS-Roper|JS-Tek|HSH-STL'}
int binning{1, prompt='Factor de binning (X,Y)'}
bool redfoc{yes, prompt='�Se us� reductor focal? (solo JS-Roper)'}
bool ganron{yes, prompt='�Calcula ganancia y ruido de lectura?'}
bool sethead{yes, prompt='�Agrega/actualiza headers (EPADU y RDNOISE)?'}
bool masterbias{no, prompt='�Genera master BIAS? (Zero)'}
bool masterflat{no, prompt='�Genera master FLAT? (FlatX)'}
bool masterdark{no, prompt='�Genera master DARK? (Dark)'}
bool borracal{no, prompt='�Borra calibraciones originales?'}
bool procesa{no, prompt='�Procesa todas las im�genes?'}
bool ovscinter{yes, prompt='�Ajusta overscan en forma interactiva? (solo JS Roper y Tek)'}
bool oscuridad{no, prompt='�Corrige por dark? (solo HSH-STL)'}
bool cosmicos{no, prompt='�Corrige por rayos c�smicos (lacos-im)?'}
real epadu{1., prompt='Valor de ganancia calculado (e-/adu)'}
real rdnoise{0., prompt='Valor de ruido de lectura calculado (e-)'}
file listbias{'', prompt='Lista de imagenes de bias'}
file listflat{'', prompt='Lista de imagenes de flat-field'}
file listdark{'', prompt='Lista de imagenes de dark (solo HSH)'}
file listima{'', prompt='Lista de imagenes a editar / reducir'}
bool flatcielo{no, prompt='�Flats de cielo? (no => dome-flats)'}
bool flatHWP{no, prompt='�Flats por cada �ngulo HWP?'}
#char ruedafilJS{'UBVRI', prompt='�Rueda de filtros TJS (UBVRI|SDSS)?',enum='UBVRI|SDSS'}
int rfilJS{2, prompt='�Rueda de filtros TJS (2=UBVRI | 1=SDSS)?'}
#char ruedafilHSH{'BVRI', prompt='�Rueda de filtros HSH (BVRI|UHaND)?',enum='BVRI|UHaND'}
char rfilHSH{'int', prompt='�Rueda de filtros HSH (int=BVRI | ext=UHaND)?',enum='int|ext'}
char base{'/home/mi-iraf/Observatorios/casleo/', prompt='directorio con datos de los CCDs'}
int xcent{988, prompt='coordenada X del centro RF (pix)'}
int ycent{1072, prompt='coordenada Y del centro RF (pix)'}
char images_path{"/home/mi-iraf/Observatorios/casleo/", prompt="Ingrese la ruta del directorio donde se encuentran las imagenes cient�ficas"}

begin

int xc, yc, radio, binxy, nf, nb, npix, x1, y1, kim, pixalto, rfcx, rfcy
int xtr1, xtr2, ytr1, ytr2, xse1, xse2, yse1, yse2, xst1, xst2, yst1, yst2
#char tlsc
char chip, sx1, sx2, sx3, sx4, sx5, tipoflat, tablaux, intmt, subst, mastf, lmf, libia, lifla, lidar, instrudb, nomim, nompl, imaux, cmnt, kw1, kw2, rfJS, rfHSH
char flat[200], bias[200]
bool rf, gr, sthd, cpc, mb, mf, md, bc, prc, ovint, drk, csmk, fhwp
file lf, lb, lima, graf1, graf2, lm
real ccdmedia, escala, pix
char covsc[5,2]="2054", "1027", "686", "0", "0", "2058", "1029", "686", "0", "0"
char lovsc[5,2]="1032", "516", "344", "0", "0", "1034", "517", "344", "0", "0"


if(!defpac('obsutil')){
obsutil
}

chip=instrumento
instrudb=base
binxy=binning
gr=ganron
sthd=sethead
mb=masterbias
mf=masterflat
bc=borracal
cpc=flatcielo
prc=procesa
ovint=ovscinter
drk=oscuridad
csmk=cosmicos
fhwp=flatHWP
rfcx=xcent
rfcy=ycent
rfJS=str(rfilJS)
rfHSH=rfilHSH

# Par�metros para el JS+Roper-2048 (directo)
if(chip=='JS-Roper'){
# escala del telescopio en arcsec/mm
escala=11.3
# tama�o del pixel en micrones
pix=13.5
npix=2048
x1=1
y1=1
rf=redfoc
md=no
if(rfJS=='1'){
  intmt=instrudb//'ccdroper_r1.dat'
  subst=instrudb//'subsets_roper_r1'
  apphot.datapars.filter = "FILTER01"
  }
if(rfJS=='2'){
  intmt=instrudb//'ccdroper_r2.dat'
  subst=instrudb//'subsets_roper_r2'
  apphot.datapars.filter = "FILTER02"
  }
ccdproc.readaxis="column"
ccdproc.darkcor=no
ccdproc.overscan=yes
pixalto=1
#rufi1='FILTER01'
#rufi2='FILTER02'
}

# Par�metros para el JS+Tek-1024 (CasPol)
if(chip=='JS-Tek'){
# escala del telescopio en arcsec/mm
escala=11.3
# tama�o del pixel en micrones
pix=24.
npix=1024
x1=1
y1=1
rf=no
md=no
if(fhwp) {
  intmt=instrudb//'ccdtek-HWP.dat'
  subst=instrudb//'subsets_caspol-HWP'
  }
  else {
  intmt=instrudb//'ccdtek.dat'
  subst=instrudb//'subsets_caspol'
  }
ccdproc.readaxis="line"
ccdproc.darkcor=no
ccdproc.overscan=yes
apphot.datapars.filter = "FILTER"
pixalto=2
}


# Par�metros para el HSH+STL-1001E
if(chip=='HSH-STL'){
# escala del telescopio en arcsec/mm
escala=22.6
# tama�o del pixel en micrones
pix=24
npix=1024
x1=1
y1=2
rf=no
md=masterdark
if(rfHSH=='int'){
  intmt=instrudb//'ccdsbig_hsh_rint.dat'
  subst=instrudb//'subsets_sbig-hsh_rint'
  apphot.datapars.filter = "FILTER"
}
if(rfHSH=='ext'){
  intmt=instrudb//'ccdsbig_hsh_rext.dat'
  subst=instrudb//'subsets_sbig-hsh_rext'
  apphot.datapars.filter = "FILTER1"
}
ccdproc.readaxis="line"
ccdproc.darkcor=drk
ccdproc.overscan=no
pixalto=1
#rufi1='FILTER1'
#rufi2='FILTER'
}

# Pixel en mm
pix=0.001*pix

print(" ")

# Archivos temporarios
lf=mktemp("tmp$casleoccd")
lmf=mktemp("tmp$casleoccd")
lb=mktemp("tmp$casleoccd")
lm=mktemp("tmp$casleoccd")
tablaux=mktemp("tmp$casleoccd")
graf1=mktemp("tmp$casleoccd")
graf2=mktemp("tmp$casleoccd")
imaux=mktemp("tmp$casleoccd")

# Listas de im�genes
libia=listbias
lifla=listflat
lidar=listdark

#files(libia, > lb)
#files(lifla, > lf)
lima=listima
#files(lima, > lm)



# Regiones para Roper c/RF
# BIASSEC (overscan)
  sx2="[*,"//covsc[binxy,1]//":"//covsc[binxy,2]//"]"
if(rf){
  radio=1300/(2.*binxy)
# centro medido
#  xc=rfcx/binxy
#  yc=rfcy/binxy

  xc=rfcx
  yc=rfcy
  
  xtr1=xc-radio-10
  xtr2=xc+radio+10
  ytr1=yc-radio-10
  ytr2=yc+radio+10

  xse1=xc-radio*dcos(45.)+10
  xse2=xc+radio*dcos(45.)-10
  yse1=yc-radio*dcos(45.)+10
  yse2=yc+radio*dcos(45.)-10

  escala=escala*3
}
# Regiones para Roper s/RF � STL-1001E
else{
  xtr1=x1
  xtr2=npix/binxy
  ytr1=y1
  ytr2=npix/binxy
#
  xse1=x1
  xse2=npix/binxy
  yse1=y1
  yse2=npix/binxy
}

# Regiones para Tek (CasPol)
if(chip=='JS-Tek'){
#
# BIASSEC (overscan)
  sx2="["//lovsc[binxy,1]//":"//lovsc[binxy,2]//",*]"
  radio=664/(2.*binxy)
# centro medido
  xc=512/binxy
  yc=500/binxy

  xtr1=1
  xtr2=npix/binxy
  ytr1=1
  ytr2=npix/binxy

  xse1=xc-radio*dcos(45.)+10
  xse2=xc+radio*dcos(45.)-10
  yse1=yc-radio*dcos(45.)+10
  yse2=yc+radio*dcos(45.)-10

  if(mf){
  list=lf
  while (fscan (list, s1) != EOF) {
  keypar(input=s1, keyw="F-HWP", silen+)
  if(!keypar.found){
    keypar(input=s1, keyw="FILTER", silen+)
    kw1=keypar.value
    keypar(input=s1, keyw="HWPLATE", silen+)
    kw2=kw1//keypar.value
    hedit(imag=s1, field='F-HWP', value=kw2, addonly+, dele-, verif-, show-, updat+)}
  }
  }

  if(prc){
  list=lm
  while (fscan (list, nomim) != EOF) {
  keypar(input=nomim, keyw="F-HWP", silen+)
  if(!keypar.found){
    keypar(input=nomim, keyw="FILTER", silen+)
    kw1=keypar.value
    keypar(input=nomim, keyw="HWPLATE", silen+)
    kw2=kw1//keypar.value
    hedit(imag=nomim, field='F-HWP', value=kw2, addonly+, dele-, verif-, show-, updat+)}
  }
}
}

  xst1=xse1-xtr1+1
  xst2=xse2-xtr1+1
  yst1=yse1-ytr1+1
  yst2=yse2-ytr1+1

# TRIMSEC (sección útil) - Como sabe/elige la seccion util?
  sx1="["//str(xtr1)//":"//str(xtr2)//","//str(ytr1)//":"//str(ytr2)//"]"
# STATSEC (caja estadísticas imagen recortada)
  sx3="["//str(xst1)//":"//str(xst2)//","//str(yst1)//":"//str(yst2)//"]"
# SECTION (caja estad�sticas imagen sin recortar)
  sx4="["//str(xse1)//":"//str(xse2)//","//str(yse1)//":"//str(yse2)//"]"

# Setea par�metros para procesamiento
  ccdproc.trimsec=sx1
  ccdproc.biassec=sx2
  ccdproc.fixpix=no
  ccdproc.trim=yes
  # Con binning > 2x2 el overscan desaparece 
  if(binxy>=3){
    ccdproc.overscan=no
  }
  ccdproc.zerocor=yes
  ccdproc.flatcor=yes
  ccdproc.illumcor=no
  ccdproc.fringecor=no
  ccdproc.function="legendre"
  ccdproc.order=4
  ccdproc.interactive=ovint
  ccdproc.zero="Zero.fits"
  ccdproc.dark="Dark.fits"
#
  zerocombine.process = yes
  zerocombine.combine = "average"
  zerocombine.reject = "minmax"
  zerocombine.statsec = ""
  zerocombine.nlow = 0
  zerocombine.nhigh = pixalto
  zerocombine.rdnoise = "RDNOISE"
  zerocombine.gain = "EPADU"
#
  darkcombine.combine = "average"
  darkcombine.reject = "minmax"
  darkcombine.ccdtype = "dark"
  darkcombine.process = yes
  darkcombine.clobber = no
  darkcombine.scale = "exposure"
  darkcombine.statsec = sx3
  darkcombine.nlow = 0
  darkcombine.nhigh = 1
  darkcombine.nkeep = 1
  darkcombine.mclip = yes
  darkcombine.lsigma = 3.
  darkcombine.hsigma = 3.
  darkcombine.rdnoise = "0."
  darkcombine.gain = "1."
  darkcombine.snoise = "0."
  darkcombine.pclip = -0.5
  darkcombine.blank = 0.
#
  flatcombine.process = yes
  flatcombine.subsets = yes
  flatcombine.scale = "median"
  flatcombine.statsec = sx3
  flatcombine.rdnoise = "RDNOISE"
  flatcombine.gain = "EPADU"
#
  ccdred.instrument = intmt
  ccdred.ssfile = subst
#
  apphot.datapars.scale=escala*pix*binxy
  apphot.datapars.ccdread = "RDNOISE"
  apphot.datapars.gain = "EPADU"
#

# Flats de cielo
if(cpc){
    print("Flats de cielo")
    tipoflat="Sky"
    flatcombine.combine = "median"
    flatcombine.reject = "avsigclip"
    flatcombine.hsigma = 2.75
#    flatcombine.ccdtype = ""
    hedit(imag=lifla, fiel="IMAGETYP", value="SKY FLAT", add-, dele-, veri-, show-, upda+)
}
# Flats de c�pula
  else{
    print("Flat de cúpula")
    tipoflat="Flat"
    flatcombine.combine = "average"
    flatcombine.reject = "crreject"
    flatcombine.hsigma = 3.
  }

ccdproc.flat=tipoflat//"*.fits"
flatcombine.output = tipoflat


# Calcula ganancia (EPADU) y ruido de lectura (RDNOISE)
if(gr){
  print("Calcula ganancia (EPADU) y ruido de lectura (RDNOISE)")
  findgain.section=sx4
	
  list=lifla
  nf=0
  while (fscan (list, s1) != EOF) {
  nf=nf+1
  flat[nf]=s1
  }
	print("B")
  list=lb
  nb=0
  while (fscan (list, s1) != EOF) {
  nb=nb+1
  bias[nb]=s1
  }

  if(nf<2) {
    print('Insuficiente cantidad de flats')
   goto FIN
  }
  if(nb<2) {
    print('Insuficiente cantidad de bias')
   goto FIN
  }

  k=1
  print("Calculando EPADU y RDNOISE ...")
  for(i=1; i<=nf-2; i+=2){
    for(j=1; j<=nb-2; j+=2){
      findgain(flat[i], flat[i+1], bias[j], bias[j+1], verb-, >> tablaux)
      }
#    if(10*(i+1)/nf>k-1){
#      print(k*10,"%")
#      k=k+1
#    }
  }
  print(" ")

print("Pone los valores de EPADU y RDNOISE en los parámetros y grafica")
# Configurar el dispositivo de gráficos para guardar en PNG
set stdimage = imt800
set stdplot = "plot.png"
gflush

tprint(tablaux, colum="c1", showr+, rows="-", > graf1)
tstat(tablaux, "c1", outta="", lowli=INDEF, highli=INDEF, rows="-")
print("EPADU = ", tstat.median)
casleoccd.epadu = tstat.median

tprint(tablaux, colum="c2", showr+, rows="-", showh-, showu-, > graf2)
tstat(tablaux, "c2", outta="", lowli=INDEF, highli=INDEF, rows="-")
print("RDNOISE = ", tstat.median)
casleoccd.rdnoise = tstat.median

sx4 = '"' // graf1 // ',' // graf2 // '"'

sgraph(input=sx4, stack+, round+, xlabel="Nr.", title="RDNOISE (arriba) - EPADU (abajo)", sysid-, pointm+, szmar=0.01)

# Guarda el gráfico como plot.png
gflush
}

# Actualiza headers

if(sthd){ 
  print("Actualiza headers")
  hedit(libia, "EPADU", casleoccd.epadu, add+, verif-, show-, updat+)
  hedit(libia, "RDNOISE", casleoccd.rdnoise, add+, verif-, show-, updat+)
#
  hedit(lidar, "EPADU", casleoccd.epadu, add+, verif-, show-, updat+)
  hedit(lidar, "RDNOISE", casleoccd.rdnoise, add+, verif-, show-, updat+)
#
  hedit(lifla, "EPADU", casleoccd.epadu, add+, verif-, show-, updat+)
  hedit(lifla, "RDNOISE", casleoccd.rdnoise, add+, verif-, show-, updat+)
#
  hedit(lima, "EPADU", casleoccd.epadu, add+, verif-, show-, updat+)
  hedit(lima, "RDNOISE", casleoccd.rdnoise, add+, verif-, show-, updat+)

# Crea clave UFILTER para subsets
#if(chip=='JS-Roper'||chip=='HSH-STL'){
#   print("Crea clave UFILTER para subsets")
#   for(i=1; i<=2; i+=1){
#    if(i==1)  list=lf
#    if(i==2)  list=lm
#list=lm
#
#    while (fscan (list, s1) != EOF) {
#      keypar(input=s1, keyw='UFILTER', silen+)
#      if(!keypar.found){
#        keypar(input=s1, keyw=rufi2, silen+)
#        s2=keypar.value
#	prfj="w2 "
#        if(substr(s2,5,8)=='Free'){
#          keypar(input=s1, keyw=rufi1, silen+)
#          s2=keypar.value
#	  prfj="w1 "
#        }
#hedit(imag=s1, field="UFILTER", value=prfj//s2, addonly+, dele-, verif-, show-, updat+)
#     }
#    }
#  }
#}
}

# Genera master BIAS
if(mb){
  print("Generando master BIAS ...")
  zeroco(input=libia, output="Zero", delete=bc)
  }

# Genera master DARK
if(md){
  print("Generando master DARK ...")
  darkcombine(input=lidar, output="Dark", delete=bc)
  }

# Genera master FLATs y actualiza CCDMEAN a la media en STATSEC
if(mf){
  print("Genera master FLATs y actualiza CCDMEAN a la media en STATSEC")
  flatcombine(input=lifla, delete=bc)
  files(tipoflat//'*', > lmf)
  list=lmf
  while (fscan (list, mastf) != EOF) {
  imstat(imag=mastf//sx3, fields='mean', lower=INDEF, upper=INDEF, format-) | scan(sx5)
  ccdmedia=real(sx5)
  hedit(imag=mastf, field='CCDMEAN', value=ccdmedia, add-, dele-, verif-, show+, upda+)
  }
  }

# Procesa im�genes
if(prc){
  print("Procesando imágenes ...")
  ccdproc(images=lima, outp="", ccdtype="object", noproc-)
}

# Corrige rayos c�smicos
if(csmk){
  print("Corrigiendo rayos c�smicos ...")
  list=lm
  while (fscan (list, nomim) != EOF) {
   print(nomim)
   kim=strlen(nomim)
   nompl=nomim//'cr.pl'
   if(substr(nomim,kim-2,kim)=="imh" || substr(nomim,kim-2,kim)=="fts" || substr(nomim,kim-2,kim)=="fit" || substr(nomim,kim-2,kim)=="FTS" || substr(nomim,kim-2,kim)=="FIT")
     nompl=substr(nomim,1,kim-4)//'cr.pl'
   if(substr(nomim,kim-3,kim)=="FITS" || substr(nomim,kim-3,kim)=="fits")
     nompl=substr(nomim,1,kim-5)//'cr.pl'

    lacos_im(inpu=nomim, outpu=imaux, outma=nompl, gain=casleoccd.epadu, readn=casleoccd.rdnoise, skyval=0., verbo-)
    imdelete(nomim, ver-)
    imrena(oldna=imaux, newna=nomim, verb-)
    keypar(nomim, keyword='COMMENT', silen+)
    if(keypar.found)
      cmnt=keypar.value//' - Cosmic-rays corrected with lacos-im'
    else
      cmnt='Cosmic-rays corrected with lacos-im'
    hedit(imag=nomim, field='COMMENT', valu=cmnt, add+, addon-, delet-, verif-, show-, updat+)
  }
}

FIN:
delete("tmp$casleoccd*", go+, ver-)
print("  ")

end
