#include <iostream>
#include <fstream>
#include <ctime>
using namespace std;

#define N 1024

#define data_t unsigned int

int main() {
    srand(time(NULL));

    data_t *A, *B, *C;
    A = new data_t[N * N];
    B = new data_t[N * N];
    C = new data_t[N * N];

    // Initialize A and B
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i*N + j] = (unsigned int)rand();
            B[i*N + j] = (unsigned int)rand();
        }
    }

    // Initialize C
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            C[i*N + j] = 0;
        }
    }

    // Multiply A and B
    // for (int i = 0; i < N; i++) {
    //     for (int k = 0; k < N; k++) {
    //         for (int j = 0; j < N; j++) {
    //             C[i][j] += A[i][k] * B[k][j];
    //         }
    //     }
    // }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            C[i*N + j] = A[i*N + j] + B[i*N + j];
        }
    }

    // Store A, B and C in row major order
    ofstream a("A.bin", ios::binary);
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            a.write((char*)&A[i*N + j], sizeof(data_t));
        }
    }

    ofstream b("B.bin", ios::binary);
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            b.write((char*)&B[i*N + j], sizeof(data_t));
        }
    }

    ofstream golden_c("golden_C.bin", ios::binary);
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            golden_c.write((char*)&C[i*N + j], sizeof(data_t));
        }
    }
}