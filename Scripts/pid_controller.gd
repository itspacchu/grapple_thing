extends  RefCounted
class_name PID

var _p;
var _i;
var _d;

var _prev_error: Vector3
var _error_integral: Vector3

func _init(p:float,i:float,d:float)->void:
	_p = p
	_i = i
	_d = d
	

func update( error: Vector3,delta: float )->Vector3:
	_error_integral += error*delta
	var err_deriv = (error - _prev_error)/delta
	_prev_error = error
	return _p * error + _i * _error_integral + _d * err_deriv
