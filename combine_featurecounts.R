files = list.files(pattern=".featureCounts")

featureCounts=read.table(files[1],row.names=1)

for (i in files[-1]){
  tmp=read.table(i,row.names=1)
  featureCounts=data.frame(featureCounts,tmp)
}

colnames(featureCounts)=substr(files,1,nchar(files)-14)
write.table(featureCounts,file="features_combined.txt",quote=F,sep='\t')

