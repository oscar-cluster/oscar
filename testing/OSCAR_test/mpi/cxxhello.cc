// -*- c++ -*-
//
// $Id: cxxhello.cc,v 1.1 2002/08/27 23:57:58 jsquyres Exp $
//
// $COPYRIGHT$
//

#include <iostream>
#include "mpi.h"

using namespace std;


int
main(int argc, char *argv[])
{
  MPI::Init(argc, argv);
  
  int rank = MPI::COMM_WORLD.Get_rank();
  int size = MPI::COMM_WORLD.Get_size();

  cout << "Hello World! I am " << rank << " of " << size << endl;
  
  MPI::Finalize();
  return 0;
}
