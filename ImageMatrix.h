//
//  ImageMatrix.h
//  SmallBarcodeReader
//
//  Matrix operations for image processing (platform-independent)
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Matrix structure for image processing
typedef struct {
    float *data;      // Matrix data (row-major order)
    int rows;         // Number of rows
    int cols;         // Number of columns
} ImageMatrix;

/// Create a new matrix
/// @param rows Number of rows
/// @param cols Number of columns
/// @return New matrix (must be freed with ImageMatrixFree)
ImageMatrix ImageMatrixCreate(int rows, int cols);

/// Free matrix memory
/// @param matrix Matrix to free
void ImageMatrixFree(ImageMatrix *matrix);

/// Get matrix element
/// @param matrix Matrix
/// @param row Row index (0-based)
/// @param col Column index (0-based)
/// @return Element value
float ImageMatrixGet(ImageMatrix matrix, int row, int col);

/// Set matrix element
/// @param matrix Matrix
/// @param row Row index (0-based)
/// @param col Column index (0-based)
/// @param value Value to set
void ImageMatrixSet(ImageMatrix matrix, int row, int col, float value);

/// Matrix multiplication: result = a * b
/// @param a First matrix
/// @param b Second matrix
/// @return Result matrix (must be freed), or invalid matrix if dimensions don't match
ImageMatrix ImageMatrixMultiply(ImageMatrix a, ImageMatrix b);

/// Create identity matrix
/// @param size Size of identity matrix
/// @return Identity matrix
ImageMatrix ImageMatrixIdentity(int size);

/// Create matrix from array (row-major order)
/// @param data Array of values
/// @param rows Number of rows
/// @param cols Number of columns
/// @return New matrix
ImageMatrix ImageMatrixFromArray(const float *data, int rows, int cols);

/// Common convolution kernels
/// @name Convolution Kernels

/// Gaussian blur kernel
/// @param size Kernel size (must be odd, e.g., 3, 5, 7)
/// @param sigma Standard deviation
/// @return Gaussian blur kernel
ImageMatrix ImageMatrixGaussianBlur(int size, float sigma);

/// Box blur kernel (uniform blur)
/// @param size Kernel size (must be odd)
/// @return Box blur kernel
ImageMatrix ImageMatrixBoxBlur(int size);

/// Sharpen kernel
/// @return Sharpen kernel (3x3)
ImageMatrix ImageMatrixSharpen(void);

/// Edge detection kernel (Sobel-like)
/// @param direction 0 for horizontal, 1 for vertical
/// @return Edge detection kernel
ImageMatrix ImageMatrixEdgeDetection(int direction);

/// Motion blur kernel
/// @param length Blur length
/// @param angle Angle in degrees
/// @return Motion blur kernel
ImageMatrix ImageMatrixMotionBlur(int length, float angle);

/// Laplacian edge detection kernel
/// @return Laplacian kernel (3x3)
ImageMatrix ImageMatrixLaplacian(void);

NS_ASSUME_NONNULL_END
