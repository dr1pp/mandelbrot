public class complex{
  
  private double real;
  private double imaginary;
  
  public complex(){
    real = 0.0;
    imaginary = 0.0;
  }
  
  public complex(double real, double imaginary){
    this.real = real;
    this.imaginary = imaginary;
  }
  
  public complex square(){
    double new_real = this.real * this.real - this.imaginary*this.imaginary;
    double new_imaginary = 2*this.real*this.imaginary;
    return new complex(new_real, new_imaginary);
  }
  
  public complex squared_modulus(){
    double abs_real = this.real * this.real;
    double abs_imag = this.imaginary * this.imaginary;
    return new complex(abs_real, abs_imag);
  }
}

complex add(complex c1, complex c2){
  return new complex(c1.real + c2.real, c1.imaginary + c2.imaginary);
}
