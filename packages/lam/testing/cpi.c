/*
 * $COPYRIGHT$
 *
 * $Id: cpi.c,v 1.1 2002/10/30 23:53:44 mchasal Exp $
 *
 * Portions taken from the MPICH distribution example cpi.c.
 *
 * Example program to calculate the value of pi by integrating f(x) =
 * 4 / (1 + x^2).
 */

#include <stdio.h>
#include <math.h>
#include "mpi.h"


/* Constant for how many values we'll estimate */

#define NUM_ITERS 1000


/* Prototype the function that we'll use below. */

static double f(double);


int
main(int argc, char *argv[])
{
  int iter, rank, size, i;
  double PI25DT = 3.141592653589793238462643;
  double mypi, pi, h, sum, x;
  double startwtime = 0.0, endwtime;
  int namelen;
  char processor_name[MPI_MAX_PROCESSOR_NAME];

  /* Normal MPI startup */

  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Get_processor_name(processor_name, &namelen);

  printf("Process %d of %d on %s\n", rank, size, processor_name);

  /* Do approximations for 1 to 100 points */

  for (iter = 2; iter < NUM_ITERS; ++iter) {
    h = 1.0 / (double) iter;
    sum = 0.0;
    
    /* A slightly better approach starts from large i and works back */

    if (rank == 0)
      startwtime = MPI_Wtime();

    for (i = rank + 1; i <= iter; i += size) {
      x = h * ((double) i - 0.5);
      sum += f(x);
    }
    mypi = h * sum;
    
    MPI_Reduce(&mypi, &pi, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
  }
    
  if (rank == 0) {
    printf("%d iterations: pi is approx. %.16f, error = %.16f\n",
           iter, pi, fabs(pi - PI25DT));
    endwtime = MPI_Wtime();
    printf("wall clock time = %f\n", endwtime - startwtime);
    fflush(stdout);
  }

  /* All done */

  MPI_Finalize();
  return 0;
}


static double
f(double a)
{
  return (4.0 / (1.0 + a * a));
}

