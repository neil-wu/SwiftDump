enum MyEnum {
	case red
	case blue
	case yellow
}

struct BaseStruct  {
	var bbname: String = "BaseStruct"
}


struct MyStruct  {
	var sid: Int = 123;
	var sname: String = "hello"
}


class BaseClass {
	var bcname: String = "BaseClass"
}


final class MyClass : BaseClass  {

	var cid: Int = 456;
	var cname: String = "world"
	var st: MyStruct? = nil;
}
