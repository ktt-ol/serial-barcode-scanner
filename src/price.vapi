[SimpleType]
[GIR (name = "gint")]
[CCode (cname = "gint", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", type_signature = "i")]
[IntegerType (rank = 6)]
public struct Price : int {
	public new string to_string() {
		return "%d.%02d".printf(this / 100, this.abs() % 100);
	}

	public static Price parse(string data) {
		if("." in data) {
			var parts = data.split(".");
			return int.parse(parts[0])*100 + int.parse(parts[1]);
		} else {
			return int.parse(data);
		}
	}
}
