/*==========================================================
 * arrayProduct.c - example in MATLAB External Interfaces
 *
 * Multiplies an input scalar (multiplier) 
 * times a 1xN matrix (inMatrix)
 * and outputs a 1xN matrix (outMatrix)
 *
 * The calling syntax is:
 *
 *		outMatrix = arrayProduct(multiplier, inMatrix)
 *
 * This is a MEX-file for MATLAB.
 * Copyright 2007-2012 The MathWorks, Inc.
 *
 *========================================================*/

#include "mex.h"
#include <stdint.h>

/* take 64 bits of data in v[0] and v[1] and 128 bits of key[0] - key[3] */

void XTEAEncipher(  unsigned int num_rounds, uint32_t v[2], 
                    uint32_t const key[4], double x[2]) {
    unsigned int i;
    uint32_t v0=v[0], v1=v[1], sum=0, delta=0x9E3779B9;
    for (i=0; i < num_rounds; i++) {
        v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + key[sum & 3]);
        sum += delta;
        v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + key[(sum>>11) & 3]);
    }
    x[0]=v0; x[1]=v1;
}

void mexFunction(   int nlhs, mxArray *plhs[],
                    int nrhs, const mxArray *prhs[]) {
    size_t      ncols, nrows;
    unsigned int num_rounds;
    uint32_t    v[2];
    uint32_t    key[4];
    double      *x;
    double      *inData;
    
    /* check for proper number of arguments */
    if(nrhs!=3) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","Three inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","One output required.");
    }
    
    /* make sure the first input argument is scalar */
    if( !mxIsDouble(prhs[0]) || 
         mxIsComplex(prhs[0]) ||
         mxGetNumberOfElements(prhs[0])!=1 ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input multiplier must be a scalar.");
    }
    /* make sure the second argument is a 2 element array */
    ncols = mxGetN(prhs[1]);
    nrows = mxGetM(prhs[1]);
    if( ncols*nrows != 2 ) {
        mexErrMsgIdAndTxt("MyToolbox:xteaEncipher:invalidDataDimension","Data must be a 2 element vector.");
    }
    
    /* make sure the third argument is a 4 element array */
    ncols = mxGetN(prhs[2]);
    nrows = mxGetM(prhs[2]);
    if( (ncols*nrows != 4) || (ncols == 2) || (nrows == 2) ) {
        mexErrMsgIdAndTxt("MyToolbox:xteaEncipher:invalidKeyDimension","Key must be a 4 element vector.");
    }
    
    /** Get Data From Arguments **/
    num_rounds = mxGetScalar(prhs[0]);
    
    inData = mxGetPr(prhs[1]);
    v[0] = (uint32_t) inData[0];
    v[1] = (uint32_t) inData[1];
    
    inData = mxGetPr(prhs[2]);
    key[0] = (uint32_t) inData[0];
    key[1] = (uint32_t) inData[1];
    key[2] = (uint32_t) inData[2];
    key[3] = (uint32_t) inData[3];
    
    /** Call Function Routine **/
    plhs[0] = mxCreateDoubleMatrix(1,2,mxREAL);
    x = mxGetPr(plhs[0]);
    XTEAEncipher(num_rounds, v, key, x);
}