

if [[ -z $1 ]];then
    echo "usage : sweep_gpu_nd.sh <path_to generate_sizes.py> <path_to bench_gpu_nd_fft>"
    echo "        will produce 2 files: bench_gpu_3d_fft.data, bench_gpu_3d_fft.err "
else

SIZES=""
if [[ -e $1 ]];then
SIZES=`python $1`
else
    echo "unable to sweep, generate_sizes.py not found at $1"
fi

for i in $SIZES;
do echo $i;
    $2 -s $i -t -a -r 20 >> bench_gpu_3d_fft.data 2>> bench_gpu_3d_fft.err 
done

for i in $SIZES;
do echo $i;
    $2 -s $i -a -r 20 >> bench_gpu_3d_fft.data 2>> bench_gpu_3d_fft.err 
done

for i in $SIZES;
do echo $i;
    $2 -s $i -r 20 >> bench_gpu_3d_fft.data 2>> bench_gpu_3d_fft.err 
done

fi