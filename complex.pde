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
  
  public double squared_modulus(){
    double abs_real = this.real * this.real;
    double abs_imag = this.imaginary * this.imaginary;
    return sqrt((float)(abs_real + abs_imag));
  }
  
  public complex add(complex a){
    return new complex(this.real + a.real, this.imaginary + a.imaginary);
  }
  
  public complex mult(double a){
    return new complex(this.real * a, this.imaginary * a);
  }
  
  public complex mult(complex a){
    return new complex((this.real * a.real) + (this.real * a.imaginary), (this.imaginary * a.imaginary) + (this.imaginary * a.real));
  }
}
