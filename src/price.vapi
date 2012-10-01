[SimpleType]
[GIR (name = "gint")]
[CCode (cname = "gint", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", type_signature = "i")]
[IntegerType (rank = 6)]
public struct Price : int {
	public new string to_string() {
		return "%d.%02d".printf(this / 100, this % 100);
	}
}
