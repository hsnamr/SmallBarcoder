//
//  ImageMatrix.m
//  SmallBarcodeReader
//
//  Matrix operations for image processing implementation
//

#import "ImageMatrix.h"
#import <math.h>
#import <stdlib.h>
#import <string.h>

ImageMatrix ImageMatrixCreate(int rows, int cols) {
    ImageMatrix matrix;
    matrix.rows = rows;
    matrix.cols = cols;
    matrix.data = (float *)calloc(rows * cols, sizeof(float));
    return matrix;
}

void ImageMatrixFree(ImageMatrix *matrix) {
    if (matrix && matrix->data) {
        free(matrix->data);
        matrix->data = NULL;
        matrix->rows = 0;
        matrix->cols = 0;
    }
}

float ImageMatrixGet(ImageMatrix matrix, int row, int col) {
    if (row < 0 || row >= matrix.rows || col < 0 || col >= matrix.cols) {
        return 0.0f;
    }
    return matrix.data[row * matrix.cols + col];
}

void ImageMatrixSet(ImageMatrix matrix, int row, int col, float value) {
    if (row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols) {
        matrix.data[row * matrix.cols + col] = value;
    }
}

ImageMatrix ImageMatrixMultiply(ImageMatrix a, ImageMatrix b) {
    if (a.cols != b.rows) {
        // Invalid dimensions - return empty matrix
        ImageMatrix result = {NULL, 0, 0};
        return result;
    }
    
    ImageMatrix result = ImageMatrixCreate(a.rows, b.cols);
    
    int i, j, k;
    for (i = 0; i < a.rows; i++) {
        for (j = 0; j < b.cols; j++) {
            float sum = 0.0f;
            for (k = 0; k < a.cols; k++) {
                sum += ImageMatrixGet(a, i, k) * ImageMatrixGet(b, k, j);
            }
            ImageMatrixSet(result, i, j, sum);
        }
    }
    
    return result;
}

ImageMatrix ImageMatrixIdentity(int size) {
    ImageMatrix matrix = ImageMatrixCreate(size, size);
    int i;
    for (i = 0; i < size; i++) {
        ImageMatrixSet(matrix, i, i, 1.0f);
    }
    return matrix;
}

ImageMatrix ImageMatrixFromArray(const float *data, int rows, int cols) {
    ImageMatrix matrix = ImageMatrixCreate(rows, cols);
    memcpy(matrix.data, data, rows * cols * sizeof(float));
    return matrix;
}

ImageMatrix ImageMatrixGaussianBlur(int size, float sigma) {
    if (size % 2 == 0) {
        size++; // Make odd
    }
    
    ImageMatrix kernel = ImageMatrixCreate(size, size);
    int center = size / 2;
    float sum = 0.0f;
    
    int i, j;
    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            int x = i - center;
            int y = j - center;
            float value = expf(-(x * x + y * y) / (2.0f * sigma * sigma));
            ImageMatrixSet(kernel, i, j, value);
            sum += value;
        }
    }
    
    // Normalize
    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            float value = ImageMatrixGet(kernel, i, j) / sum;
            ImageMatrixSet(kernel, i, j, value);
        }
    }
    
    return kernel;
}

ImageMatrix ImageMatrixBoxBlur(int size) {
    if (size % 2 == 0) {
        size++; // Make odd
    }
    
    ImageMatrix kernel = ImageMatrixCreate(size, size);
    float value = 1.0f / (size * size);
    
    int i, j;
    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            ImageMatrixSet(kernel, i, j, value);
        }
    }
    
    return kernel;
}

ImageMatrix ImageMatrixSharpen(void) {
    // Standard sharpen kernel
    float data[] = {
         0, -1,  0,
        -1,  5, -1,
         0, -1,  0
    };
    return ImageMatrixFromArray(data, 3, 3);
}

ImageMatrix ImageMatrixEdgeDetection(int direction) {
    ImageMatrix kernel = ImageMatrixCreate(3, 3);
    
    if (direction == 0) {
        // Horizontal edge detection (Sobel)
        float data[] = {
            -1, -2, -1,
             0,  0,  0,
             1,  2,  1
        };
        memcpy(kernel.data, data, 9 * sizeof(float));
    } else {
        // Vertical edge detection (Sobel)
        float data[] = {
            -1,  0,  1,
            -2,  0,  2,
            -1,  0,  1
        };
        memcpy(kernel.data, data, 9 * sizeof(float));
    }
    
    return kernel;
}

ImageMatrix ImageMatrixMotionBlur(int length, float angle) {
    if (length < 1) length = 1;
    if (length % 2 == 0) length++; // Make odd
    
    ImageMatrix kernel = ImageMatrixCreate(length, length);
    
    // Convert angle to radians
    float angleRad = angle * M_PI / 180.0f;
    float dx = cosf(angleRad);
    float dy = sinf(angleRad);
    
    int center = length / 2;
    float sum = 0.0f;
    
    int i, j;
    for (i = 0; i < length; i++) {
        for (j = 0; j < length; j++) {
            int x = i - center;
            int y = j - center;
            
            // Check if point is on the line
            float dist = fabsf(x * dy - y * dx);
            if (dist < 0.5f) {
                float value = 1.0f;
                ImageMatrixSet(kernel, i, j, value);
                sum += value;
            }
        }
    }
    
    // Normalize
    if (sum > 0.0f) {
        for (i = 0; i < length; i++) {
            for (j = 0; j < length; j++) {
                float value = ImageMatrixGet(kernel, i, j) / sum;
                ImageMatrixSet(kernel, i, j, value);
            }
        }
    }
    
    return kernel;
}

ImageMatrix ImageMatrixLaplacian(void) {
    // Laplacian edge detection kernel
    float data[] = {
         0, -1,  0,
        -1,  4, -1,
         0, -1,  0
    };
    return ImageMatrixFromArray(data, 3, 3);
}
