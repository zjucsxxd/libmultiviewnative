#define BOOST_TEST_DYN_LINK 
#define BOOST_TEST_MODULE CUDA_MEMORY_SUITE
#include "boost/test/unit_test.hpp"
#include "test_fixtures.hpp"
#include "cuda_memory.cuh"

template <typename T>
__global__ void add_1(T* _container, unsigned _size){

  unsigned global = threadIdx.x + blockIdx.x*blockDim.x;

  if(global < _size)
    _container[global] += 1.f;
  
}

typedef multiviewnative::stack_on_device<multiviewnative::image_stack, multiviewnative::asynch> asynch_stack_on_device;
typedef multiviewnative::stack_on_device<multiviewnative::image_stack, multiviewnative::synch>  synch_stack_on_device;

BOOST_FIXTURE_TEST_SUITE( constructor_suite, multiviewnative::default_3D_fixture )
   
BOOST_AUTO_TEST_CASE( instantiate )
{
  asynch_stack_on_device nullary;
  BOOST_CHECK_MESSAGE(nullary.host_stack_ == 0, "strange, stack_on_device has host memory loaded although it was constructed without any argument");
}

BOOST_AUTO_TEST_CASE( by_copy )
{
  asynch_stack_on_device simple(image_);
  BOOST_CHECK_MESSAGE(simple.host_stack_ != 0, "stack_on_device has no host memory loaded");
  BOOST_CHECK_MESSAGE(simple.device_stack_ptr_ != 0, "stack_on_device has no device memory loaded");
}


BOOST_AUTO_TEST_CASE( by_operator_equal )
{
  asynch_stack_on_device simple = (image_);
  BOOST_CHECK_MESSAGE(simple.host_stack_ != 0, "stack_on_device has no host memory loaded");
  BOOST_CHECK_MESSAGE(simple.device_stack_ptr_ != 0, "stack_on_device has no device memory loaded");
}
BOOST_AUTO_TEST_SUITE_END()

BOOST_FIXTURE_TEST_SUITE( offload_suite, multiviewnative::default_3D_fixture )
   
BOOST_AUTO_TEST_CASE( instantiate_add_1_synched )
{
  using namespace multiviewnative;

  unsigned sum_original = std::accumulate(image_.data(), image_.data() + image_.num_elements(), 0.);
  synch_stack_on_device simple = image_;
  
  simple.push_to_device();

  dim3 blocks = image_.shape()[2];
  dim3 threads = image_.shape()[1]*image_.shape()[0];
  
  add_1<<<blocks,threads>>>(simple.device_stack_ptr_, image_.num_elements());

  simple.pull_from_device();

  unsigned sum = std::accumulate(image_.data(), image_.data() + image_.num_elements(), 0.);
  
  BOOST_CHECK_NE(sum_original, sum);
  BOOST_CHECK_EQUAL(sum_original+image_.num_elements(), sum);
}

BOOST_AUTO_TEST_CASE( instantiate_add_1_asynched )
{
  using namespace multiviewnative;
  cudaStream_t tstream;
  cudaStreamCreate(&tstream);

  unsigned sum_original = std::accumulate(image_.data(), image_.data() + image_.num_elements(), 0.);
  asynch_stack_on_device simple = image_;
  
  simple.push_to_device(&tstream);

  dim3 blocks = image_.shape()[2];
  dim3 threads = image_.shape()[1]*image_.shape()[0];
  
  add_1<<<blocks,threads, 0 , tstream>>>(simple.device_stack_ptr_, image_.num_elements());

  simple.pull_from_device(&tstream);

  cudaStreamSynchronize(tstream);
  unsigned sum = std::accumulate(image_.data(), image_.data() + image_.num_elements(), 0.);
  
  BOOST_CHECK_NE(sum_original, sum);
  BOOST_CHECK_EQUAL(sum_original+image_.num_elements(), sum);
  cudaStreamDestroy(tstream);
}

BOOST_AUTO_TEST_SUITE_END()

















