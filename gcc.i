%module(directors="1") ARM

%include <stdint.i>
//%include <typemaps.i>
//%include <cpointer.i>
%include <std_string.i>
%include <enumtypeunsafe.swg>
//%include <enumsimple.swg>
%include <swiginterface.i>
%include <arrays_java.i>
%include <carrays.i>
//%include <various.i>

%javaconst(1);

#define _GNU_SOURCE
#define LINUX
#define __SERVER__
#define _ENABLE_EPOLL

//%insert("runtime") %{
//#define SWIG_JAVA_NO_DETACH_CURRENT_THREAD
//%}
 
#ifdef SWIG
#define LIBUTIL_EXPORT 
#endif

%ignore gcc_create_provider_ex(GCC_Provider** provider); 
%ignore gcc_destroy_provider_ex(GCC_Provider* provider); 
%ignore gcc_create_provider(GCC_Provider** provider);
%ignore gcc_heart_beat();

%ignore CAPI_Object;
%ignore PKI_Data;
%ignore wbxConfId::value() const;
%ignore wbxConfId::operator=(unsigned int conf_id);
%ignore wbxConfId::operator=(const char* conf_id);
%ignore wbxConfId::operator=(const wbxConfId& conf_id);	
%ignore wbxConfId::operator==(wbxConfId & conf_id) const;
%ignore wbxConfId::operator > (unsigned int) const;
%ignore wbxConfId::operator >= (unsigned int) const;
%ignore wbxConfId::operator < (unsigned int) const;
%ignore Compare_confid;
%ignore T120_REF_Object;

%ignore gcc_join_conference(
	Transport_Address			local_address,
	WbxArmServerAddress*		server_addr,
	WbxArmConfAttribute*		conf_attrib,
	boolean						create_or_join,	// true for create, false for join
	WbxArmConfCreateOption*		conf_create_option,
	uint16						num_of_resource,
	GCC_Resource**				resource_list,
	uint8*						user_data,
	uint32						user_data_length,
	GCC_Enroll_Flag				enroll_flag,
	uint8*						node_info,
	uint32						node_info_length,
	ArmCallback					callback,
	void*						user_defined);

%ignore gcc_rejoin_conference(
	uint32                  conference_id);


// convert char** in C++ to String[] in java
/*%typemap(directorin, descriptor="[Ljava/lang/String;") (uint16 num_of_ping_svrs, char** ping_server_list) { 
	// need to free ??
	jobjectArray jo = NULL;
	if($2 != NULL)
	{
		jo = (jobjectArray)jenv->NewObjectArray($1, 
							jenv->FindClass("java/lang/String"),
         					jenv->NewStringUTF(""));
		for(int i=0; i<$1; i++)
		{
			jenv->SetObjectArrayElement(jo, i, jenv->NewStringUTF($2[i]));
		}		
	}
	
	$input = jo;
}
*/
%typemap(jni) char * token "jobject"
%typemap(jtype) char * token "StringBuffer"
%typemap(jstype) char * token "StringBuffer"
%typemap(javain) char * token  "$javainput"

%typemap(in) char * token {
    $1 = NULL;
    if($input != NULL) {
      /* Get the String from the StringBuffer */
      jmethodID setLengthID;
      jclass sbufClass = JCALL1(GetObjectClass, jenv, $input);
      jmethodID toStringID = JCALL3(GetMethodID,jenv, sbufClass, "toString", "()Ljava/lang/String;");
      jstring js = (jstring)JCALL2(CallObjectMethod, jenv, $input, toStringID);

      /* Convert the String to a C string */
      const char *pCharStr = JCALL2(GetStringUTFChars, jenv, js, 0);

      /* Take a copy of the C string as the typemap is for a non const C string */
      jmethodID capacityID = JCALL3(GetMethodID, jenv, sbufClass, "capacity", "()I");
      jint capacity = JCALL2(CallIntMethod, jenv, $input, capacityID);
      $1 = (char *) malloc(capacity+1);
      strcpy($1, pCharStr);

      /* Release the UTF string we obtained with GetStringUTFChars */
      JCALL2(ReleaseStringUTFChars, jenv,  js, pCharStr);

      /* Zero the original StringBuffer, so we can replace it with the result */
      setLengthID = JCALL3(GetMethodID, jenv, sbufClass, "setLength", "(I)V");
      JCALL3(CallVoidMethod, jenv, $input, setLengthID, (jint) 0);
    }
}

%typemap(argout) char *token {

  if($1 != NULL) {
    /* Append the result to the empty StringBuffer */
    jstring newString = JCALL1(NewStringUTF, jenv, $1);
    jclass sbufClass = JCALL1(GetObjectClass, jenv, $input);
    jmethodID appendStringID = JCALL3(GetMethodID, jenv, sbufClass, "append", "(Ljava/lang/String;)Ljava/lang/StringBuffer;");
    JCALL3(CallObjectMethod, jenv, $input, appendStringID, newString);

    /* Clean up the string object, no longer needed */
    free($1);
    $1 = NULL;
  }  
}

%typemap(freearg) char *token ""

%typemap(jni) (uint16 number_of_handles, NameHandle* name_handle_list) "jobjectArray"
%typemap(jtype) (uint16 number_of_handles, NameHandle* name_handle_list) "NameHandle[]"
%typemap(jstype) (uint16 number_of_handles, NameHandle* name_handle_list) "NameHandle[]"
%typemap(javain) (uint16 number_of_handles, NameHandle* name_handle_list) "$javainput"
%typemap(in) (uint16 number_of_handles, NameHandle* name_handle_list) {
	if($input != NULL)
	{
		$1 = JCALL1(GetArrayLength, jenv, $input);
		$2 = new NameHandle[$1];
		jclass name_handle_cls = JCALL1(FindClass, jenv, "Lcom/webex/eureka/arm/wrapper/NameHandle;");
		//jobject jNameHandle = (jobject)JCALL2(GetObjectArrayElement, jenv, $input, 0);
		//jclass name_handle_cls = JCALL1(GetObjectClass, jenv, jNameHandle);
		
		jmethodID get_handle_name_id = JCALL3(GetMethodID, jenv, name_handle_cls, "getHandle_name", "()Ljava/lang/String;");
		jmethodID get_handle_value_id = JCALL3(GetMethodID, jenv, name_handle_cls, "getHandle_value", "()J");
		for(int i=0;i<$1;i++) {
			jobject handle = (jobject)JCALL2(GetObjectArrayElement, jenv, $input, i);
			jstring handle_name = (jstring)JCALL3(CallObjectMethod, jenv, handle, get_handle_name_id, NULL);
			const char * c_string = JCALL2(GetStringUTFChars, jenv, handle_name, 0);
			$2[i].handle_value = (long)JCALL3(CallLongMethod, jenv, handle, get_handle_value_id, NULL);
			strcpy($2[i].handle_name, c_string);
			JCALL2(ReleaseStringUTFChars, jenv, handle_name, c_string);
			JCALL1(DeleteLocalRef, jenv, handle_name);
			JCALL1(DeleteLocalRef, jenv, handle);
		}
	}
}

%typemap(freearg) (uint16 number_of_handles, NameHandle* name_handle_list) {
	if($2 != NULL) 
	{
		delete[] $2;
	}
}

%typemap(javadirectorin) (uint16 number_of_handles, NameHandle* name_handle_list) "$jniinput"
%typemap(directorin, descriptor="[Lcom/webex/eureka/arm/wrapper/NameHandle;") (uint16 number_of_handles, NameHandle* name_handle_list) { 
	if($2 != NULL)
	{
		jclass name_handle_cls = JCALL1(FindClass, jenv, "Lcom/webex/eureka/arm/wrapper/NameHandle;");
		jobjectArray objArray = (jobjectArray)JCALL3(NewObjectArray, jenv, (jsize)$1, name_handle_cls, NULL);
		jmethodID constructorId = JCALL3(GetMethodID, jenv, name_handle_cls, "<init>", "()V");
		jmethodID set_handle_name_id = JCALL3(GetMethodID, jenv, name_handle_cls, "setHandle_name", "(Ljava/lang/String;)V");
		jmethodID set_handle_value_id = JCALL3(GetMethodID, jenv, name_handle_cls, "setHandle_value", "(J)V");
		for(int i=0;i<$1;i++) {
			jobject handle = JCALL2(NewObject, jenv, name_handle_cls, constructorId);
			jstring name = JCALL1(NewStringUTF, jenv, $2[i].handle_name);
			JCALL3(CallVoidMethod, jenv, handle, set_handle_name_id, name);
			JCALL3(CallVoidMethod, jenv, handle, set_handle_value_id, $2[i].handle_value);
			JCALL3(SetObjectArrayElement, jenv, objArray, i, handle);
			JCALL1(DeleteLocalRef, jenv, name);
			JCALL1(DeleteLocalRef, jenv, handle);
		}
	    $input = objArray; 	
	}
	else
	{
		$input = NULL;
	}
}

//virtual GCC_Error arm_ape_attach(
//   wbxConfId&              conference_id,
//   ARM_APE_Sink*           arm_ape_sink,
 //  ARM_APE**               arm_ape)

%nodefaultctor ARM_APE;
%nodefaultdtor ARM_APE;
%nodefaultctor CAS_APE;
%nodefaultdtor CAS_APE;
 
%typemap(javacode) ARM_APE %{
	 public ARM_APE() {
		 this(0, false);
	 }
%}

%typemap(javacode) GCC_Session_Key %{
	@Override
	public boolean equals(Object obj) {
		GCC_Session_Key key = (GCC_Session_Key)obj;
		return (this.getApplication_protocol_type() == key.getApplication_protocol_type()
			&& this.getSession_id() == key.getSession_id());
	  }
%}
	
%typemap(jni) ARM_APE ** "jobject"
%typemap(jtype) ARM_APE ** "ARM_APE"
%typemap(jstype) ARM_APE ** "ARM_APE"
%typemap(javain) ARM_APE ** "$javainput"

%typemap(in) ARM_APE ** (ARM_APE *ppARM_APE = 0) %{
	$1 = &ppARM_APE;
%}

%typemap(argout) ARM_APE ** {
	jclass clazz = JCALL1(FindClass, jenv, "com/webex/eureka/arm/wrapper/ARM_APE");
	jfieldID fid = JCALL3(GetFieldID, jenv, clazz, "swigCPtr", "J");
	jlong cPtr = 0;
	*(ARM_APE **)&cPtr = *$1;
	JCALL3(SetLongField, jenv, $input, fid, cPtr);
}

%typemap(jni) (uint16 num_of_ping_svrs, char** ping_server_list) "jobjectArray"
%typemap(jtype) (uint16 num_of_ping_svrs, char** ping_server_list) "String[]"
%typemap(jstype) (uint16 num_of_ping_svrs, char** ping_server_list) "String[]"

%typemap(javain) (uint16 num_of_ping_svrs, char** ping_server_list) "$javainput"
%typemap(in) (uint16 num_of_ping_svrs, char** ping_server_list) {
    int i = 0;
	if($input != NULL)
	{
		$1 = JCALL1(GetArrayLength, jenv, $input);
		$2 = (char **) malloc(($1+1)*sizeof(char *));
	    /* make a copy of each string */
	    for (i = 0; i<$1; i++) {
	        jstring j_string = (jstring)JCALL2(GetObjectArrayElement, jenv, $input, i);
	        const char * c_string = JCALL2(GetStringUTFChars, jenv, j_string, 0);
	        $2[i] = (char*)malloc((strlen(c_string)+1)*sizeof(char));
	        strcpy($2[i], c_string);
			JCALL2(ReleaseStringUTFChars, jenv, j_string, c_string);
			JCALL1(DeleteLocalRef, jenv, j_string);
	    }
	    $2[i] = 0;
	}
	else
	{	$1 = 0;
		$2 = NULL;
	}
}

%typemap(freearg) (uint16 num_of_ping_svrs, char** ping_server_list) {
    int i;
	if($2 != NULL) 
	{
	    for (i=0; i<$1-1; i++)
	      free($2[i]);
	    free($2);	
	}
}

// convert c++ buffer to java byte[]
%typemap(jni) (uint8* data, uint32 data_length) "jbyteArray"
%typemap(jtype) (uint8* data, uint32 data_length) "byte[]"
%typemap(jstype) (uint8* data, uint32 data_length) "byte[]"
%typemap(javain) (uint8* data, uint32 data_length) "$javainput"
%typemap(javadirectorin) (uint8* data, uint32 data_length) "$jniinput"

%typemap(in, numinputs=1) (uint8* data, uint32 data_length) {
	if($input != NULL)
	{
		$1 = ($1_ltype)JCALL2(GetByteArrayElements, jenv, $input, NULL); 
		$2 = JCALL1(GetArrayLength, jenv, $input);	
	}
	else
	{	$1 = ($1_ltype)0;
		$2 = 0;
	}
}

%typemap(freearg) (uint8* data, uint32 data_length) {
  // Or use  0 instead of ABORT to keep changes if it was a copy
  if($1 != NULL)
  {
    	JCALL3(ReleaseByteArrayElements, jenv, $input, (jbyte*)$1, JNI_ABORT); 	
  }
}

%typemap(directorin, descriptor="[B") (uint8* data, uint32 data_length) { 
	if($1 != NULL)
	{
	    jbyteArray jb = JCALL1(NewByteArray, jenv, $2);
		JCALL4(SetByteArrayRegion, jenv, jb, 0, $2, (jbyte *)$1);
	    $input = jb; 	
	}
	else
	{
		$input = NULL;
	}
}
 
// for output arg with director
//%typemap(directorargout) (uint8* data, uint32 data_length) {
//	if($input != NULL)
//	{
//		JCALL4(GetByteArrayRegion, jenv, $input, 0, $2, (jbyte *)$1);		
//	}
//} 

%apply (uint8* data, uint32 data_length) {
	(uint8* user_data, uint32 user_data_length), 
	(uint8* key, uint32 key_len), 
	(uint8* message_data, uint32 message_length), 
	(uint8* user_cert, uint32 user_cert_length), 
	(uint8* ape_info, uint32 ape_info_length), 
	(uint8* opt, uint32 opt_length), 
	(uint8* opt_data, uint32 opt_data_length),
    (uint8* node_info, uint32 node_info_length),
	(uint8* message, uint32 message_length)
};
 
%typemap(jtype) (uint32 length, uint8* data) "byte[]"
%typemap(jstype) (uint32 length, uint8* data) "byte[]"
%typemap(jni) (uint32 length, uint8* data) "jbyteArray"
%typemap(javain) (uint32 length, uint8* data) "$javainput"
%typemap(javadirectorin) (uint32 length, uint8* data) "$jniinput"

%typemap(in, numinputs=1) (uint32 length, uint8* data) {
	if($input != NULL)
	{
		$1 = JCALL1(GetArrayLength, jenv, $input);
		$2 = ($2_ltype)JCALL2(GetByteArrayElements, jenv, $input, NULL); 	
	}
	else
	{	$1 = 0;
		$2 = ($2_ltype)0;
	}
}

%typemap(directorin, descriptor="[B") (uint32 length, uint8* data) { 
	
	if($2 != NULL)
	{
	    jbyteArray jb = JCALL1(NewByteArray, jenv, $1);
		JCALL4(SetByteArrayRegion, jenv, jb, 0, $1, (jbyte *)$2);
	    $input = jb; 	
	}
	else
	{
		$input = NULL;
	}
}

//%typemap(argout) (uint32& encrypted_data_len, uint8*& encrypted_data) {
//	$result = JCALL1(NewByteArray, jenv, $1);
//	JCALL4(SetByteArrayRegion, jenv, $result, 0, $1, (jbyte*)&$2);
//}

%typemap(freearg) (uint32 length, uint8* data) {
  // Or use  0 instead of ABORT to keep changes if it was a copy
  if($2 != NULL)
  {
  	  JCALL3(ReleaseByteArrayElements, jenv, $input, (jbyte*)$2, JNI_ABORT); 
  }
}

%apply (uint32 length, uint8* data) {(uint32 length, const uint8* data)};

%typemap(jni) (uint8* data) "jbyteArray"
%typemap(jtype) (uint8* data) "byte[]"
%typemap(jstype) (uint8* data) "byte[]"
%typemap(javain) (uint8* data) "$javainput"
%typemap(javaout) (uint8* data) {
	return $jnicall;
}

%typemap(in) (uint8* data) {
	if($input != NULL)
	{
		$1 = ($1_ltype)JCALL2(GetByteArrayElements, jenv, $input, NULL); 	
	}
	else
	{
		$1 = ($1_ltype)0;
	}
}

%typemap(out) (uint8* data) {
	if($1 != NULL)
	{
		$result = JCALL1(NewByteArray, jenv, arg1->length);
		JCALL4(SetByteArrayRegion, jenv, $result, 0, arg1->length,  (jbyte *)$1);		
	}
}

%typemap(jni) (uint8* ape_info) "jbyteArray"
%typemap(jtype) (uint8* ape_info) "byte[]"
%typemap(jstype) (uint8* ape_info) "byte[]"
%typemap(javain) (uint8* ape_info) "$javainput"
%typemap(javaout) (uint8* ape_info) {
	return $jnicall;
}

%typemap(in) (uint8* ape_info) {
	if($input != NULL)
	{
		$1 = ($1_ltype)JCALL2(GetByteArrayElements, jenv, $input, NULL); 	
	}
	else
	{
		$1 = ($1_ltype)0;
	}
}

%typemap(out) (uint8* ape_info) {
	if($1 != NULL)
	{
		$result = JCALL1(NewByteArray, jenv, arg1->ape_info_length);
		JCALL4(SetByteArrayRegion, jenv, $result, 0, arg1->ape_info_length,  (jbyte *)$1);		
	}
}

%interface_impl(GCC_Node_Controller_SAP_Sink);
%interface_impl(GCC_ARM_Cache_Sink);
%interface_impl(ARM_APE_Sink);
%interface_impl(CAS_APE_Sink);

//%pointer_class(int, intp);
//%pointer_class(void, voidp);
//%pointer_functions(unsigned char, ucharp);

%feature("notabstract") GCC_Provider;
%feature("notabstract") ARM_APE;
%feature("notabstract") CAS_APE;

%nodefaultctor GCC_Provider;
%nodefaultdtor GCC_Provider;

%extend GCC_Provider {
	GCC_Provider() {
		GCC_Provider *pGCC_Provider = 0;
		gcc_create_provider_ex(&pGCC_Provider);
		return pGCC_Provider;
	}
	
	~GCC_Provider() {
		gcc_destroy_provider_ex($self);
	}
};

%typemap(jni) GCC_Provider ** "jobject"
%typemap(jtype) GCC_Provider ** "GCC_Provider"
%typemap(jstype) GCC_Provider ** "GCC_Provider"

%typemap(in) GCC_Provider ** (GCC_Provider *ppGCC_Provider = 0) {
	$1 = &ppGCC_Provider;
}

%typemap(argout) GCC_Provider ** {
	jclass clazz = (*jenv)->FindClass(jenv, "GCC_Provider");
	jfieldID fid = (*jenv)->GetFieldID(jenv, clazz, "swigCPtr", "J");
	jlong cPtr = 0;
	*(GCC_Provider **)&cPtr = *$1;
	(*jenv)->SetLongField(jenv, $input, fid, cPtr);
}

%typemap(javain) GCC_Provider ** "$javainput"

%{
#include "platform.h"
#include "wbxconfid.h"
#include "t120defs.h"
#include "t120base.h"
#include "gcc.h"
#include "apptokenutil.h"
%}

%array_functions(GCC_Resource*, GCC_Resource_Array);
%array_functions(GCC_Resource_Update_Record*, GCC_Resource_Update_Record_Array);
%array_functions(GCC_Node_Record*, GCC_Node_Record_Array);
%array_functions(GCC_APE_Record*, GCC_APE_Record_Array);
%array_functions(NameHandle, NameHandle_Array);

%feature("ref")   T120_Object "$this->add_reference();"
%feature("unref") T120_Object "$this->release_reference();"

//%feature("director") GCC_Node_Controller_SAP_Sink;
//%feature("director") GCC_ARM_Cache_Sink;
%feature("director") GCC_Client_Sink;
%feature("director") JAVA_ARM_APE_Sink;
%feature("director") JAVA_CAS_APE_Sink;
%feature("director") T120_Timer_Object;
%feature("director") T120_Object;


//%feature("director") ARM_APE_Sink;
//%feature("director") CAS_APE_Sink;

%pragma(java) jniclasscode=%{
  static {
    try {
      System.loadLibrary("armWrapper");
    } catch (UnsatisfiedLinkError e) {
      System.err.println("Native code library failed to load. \n" + e);
      System.exit(1);
    }
  }
%}

%include "platform.h"
%include "wbxconfid.h"
%include "t120defs.h"
%include "t120base.h"
%include "gcc.h"
%include "apptokenutil.h"

%inline %{
	
	class GCC_Client_Sink: public GCC_Node_Controller_SAP_Sink, public GCC_ARM_Cache_Sink
	{
	public:
		virtual ~GCC_Client_Sink() {};
					
	public:
		virtual ARM_Error on_namehandle_allocate_confirm(
		uint16					      number_of_handles,
		NameHandle*						name_handle_list,
		GCC_Result					   result) {return 0;}

		virtual ARM_Error on_cache_action_confirm_ex(
		uint32					cache_handle,
		CacheAction				cache_action,
		uint32					reqeust_idx,
		uint32					cache_id,
		GCC_Result				result){return 0;}

		virtual ARM_Error on_cache_retrieve_confirm_ex(
		uint32							cache_handle,
		uint32							group_id,
		uint32							reqeust_idx,
		uint32							cache_id,
		CacheAction						cache_action,
		GCC_Result						result,
		MCS_Priority					priority,
		uint8*							data,
		uint32							data_length){return 0;}
							
		virtual GCC_Error on_ping_confirm(
		boolean                     to_create,
		WBXCONFID&                      conference_id,
		Transport_Address           cb_address,
		Transport_Address           gateway_address,
		Transport_Address           top_cb_address,
		Ping_Result                 result){return 0;}

		virtual GCC_Error on_conference_create_confirm(
		char*                       conference_name,
		char*                       conference_key,
		WBXCONFID                      conference_id,
		GCC_Node_ID                 local_node_id,
		GCC_Node_ID                 sup_node_id,
		GCC_Node_ID                 top_node_id,
		uint16                      num_of_resource,
		GCC_Resource**              resource_list,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_join_confirm(
		char*                       conference_name,
		char*                       conference_key,
		WBXCONFID                      conference_id,
		boolean                     conference_is_locked,
		GCC_Node_ID                 local_node_id,
		GCC_Node_ID                 sup_node_id,
		GCC_Node_ID                 top_node_id,
		uint16                      num_of_resource,
		GCC_Resource**              resource_list,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_disconnect_confirm(
		WBXCONFID&                      conference_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_disconnect_indication(
		WBXCONFID&                      conference_id,
		GCC_Reason                  reason,
		GCC_Node_ID                 disconnecting_node_id){return 0;}

		virtual GCC_Error on_conference_terminate_confirm(
		WBXCONFID&                      conference_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_terminate_indication(
		WBXCONFID&                      conference_id,
		GCC_Node_ID                 requesting_node_id,
		GCC_Reason                  reason){return 0;}

		virtual GCC_Error on_conference_lock_report_indication(
		WBXCONFID&                      conference_id,
		boolean                     conference_is_locked){return 0;}

		virtual GCC_Error on_conference_parameter_change_indication(
		WBXCONFID&                      conference_id,
		uint16                      num_of_resource,
		GCC_Resource_Update_Record** update_rsc_list){return 0;}

		virtual GCC_Error on_conference_eject_user_confirm(
		WBXCONFID&                      conference_id,
		GCC_Node_ID                 ejected_node_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_eject_user_indication(
		WBXCONFID&                      conference_id,
		GCC_Node_ID                 ejected_node_id,
		GCC_Reason                  reason){return 0;}

		virtual GCC_Error on_conference_announce_presence_confirm(
		WBXCONFID&                      conference_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_conference_roster_report_indication(
		WBXCONFID&                      conference_id,
		uint16                      number_of_total_nodes,
		uint16                      number_of_node_instances,
		uint16                      number_of_added_nodes,
		uint16                      number_of_removed_nodes,
		GCC_Node_Record**           node_list){return 0;}

		virtual GCC_Error on_host_change_indication(
		WBXCONFID&                      conference_id,
		uint32                      host_node_id){return 0;}

		virtual GCC_Error on_host_assign_confirm(
		WBXCONFID&                      conference_id,
		uint32                      recipient_node_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_presentor_change_indication(
		WBXCONFID&                      conference_id,
		uint32                      presenter_node_id){return 0;}

		virtual GCC_Error on_presentor_assign_confirm(
		WBXCONFID&                      conference_id,
		uint32                      recipient_node_id,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_message_indication(
		WBXCONFID&                      conference_id,
		GCC_Node_ID                 from_node_id,
		GCC_Node_ID                 dest_node_id,
		uint8*                      message,
		uint32                      message_length) {return 0;}

		virtual GCC_Error on_session_create_confirm(
		WBXCONFID&                      conference_id,
		uint32                      req_handle,
		GCC_Session_Key*            session_key,
		uint16                      num_of_resource,
		GCC_Resource**              resource_list,
		GCC_Result                  result){return 0;}

		virtual GCC_Error on_session_create_indication(
		WBXCONFID&                      conference_id,
		GCC_Session_Key*            session_key,
		uint16                      num_of_resource,
		GCC_Resource**              resource_list,
		GCC_Node_ID                 initiator_node){return 0;}

		virtual GCC_Error on_session_close_indication(
		WBXCONFID&                      conference_id,
		GCC_Session_Key*            session_key,
		GCC_Reason                  reason){return 0;}

		virtual GCC_Error on_flow_control_alarm(
		WBXCONFID&                      conference_id,
		MCS_Node_ID                 initiator_node,
		uint16                      number_of_nodes,
		MCS_Node_ID*                node_list,
		uint16                      number_of_priorities,
		MCS_Flow_Control_Alarm_Status* status){return 0;}

		virtual GCC_Error on_misc_msg_indication(
		uint32                      msg_type,
		uint32                      msg_data
			){return 0;}

		//{ 11/12/2007, Folki+ for dynamic channel
		virtual GCC_Error on_channel_join_confirm(
		WBXCONFID&							conf_id,
		MCS_Channel_ID					chan_id,
		GCC_Result						result){return 0;}
	};
	
	class JAVA_ARM_APE_Sink: public ARM_APE_Sink
	{
	public:
		virtual ~JAVA_ARM_APE_Sink() {};
	public :
	   	virtual ARM_Error on_detach_indication(
	      GCC_Session_Key*            session_key,
	      GCC_Reason                  reason) {return 0;}

	   	virtual ARM_Error on_session_enroll_confirm(
	      GCC_Session_Key*            session_key,
	      GCC_Result                  result) {return 0;}

	   	virtual ARM_Error on_session_parameter_change_indication(
	      GCC_Session_Key*            session_key,
	      uint16                      num_of_resource,
	      GCC_Resource_Update_Record** update_rsc_list) {return 0;}

	   	virtual ARM_Error on_data_indication(
	      GCC_Session_Key*            session_key,
	      MCS_User_ID                 sender_id,
	      MCS_Channel_ID              channel_id,
	      boolean                     uniform,
	      MCS_Priority                priority,
	      uint8*                      data,
	      uint32                      data_length) {return 0;}
	   	virtual ARM_Error on_data_indication_h264_data(
		   GCC_Session_Key*            session_key,
		   MCS_User_ID                 sender_id,
		   MCS_Channel_ID              channel_id,
	       MCS_Priority                priority,
		   uint8*              user_data,
		   uint32              user_data_length,
		   uint32               frame_tag,
		   uint32				data_type){return 0;}
		//jamie add for mobile gateway
	   	virtual ARM_Error on_data_indication_flv(
	      GCC_Session_Key*            session_key,
	      MCS_User_ID                 sender_id,
	      MCS_Channel_ID              channel_id,
	      boolean                     uniform,
	      MCS_Priority                priority,
	      uint8*                      data,
	      uint32                      data_length,
	      uint32               tag_flag) {return 0;}

	   	virtual ARM_Error on_applicaiton_roster_report_indication(
	      GCC_Session_Key*            session_key,
	      uint16                      number_of_total_entities,
	      uint16                      number_of_entity_instances,
	      uint16                      number_of_added_entities,
	      uint16                      number_of_removed_entities,
	      GCC_APE_Record**            entity_list) {return 0;}
		  
	   	virtual ARM_Error on_token_grab_confirm(
	      MCS_Token_ID                token_id,
	      uint16                      result) {return 0;}

	   	virtual ARM_Error on_token_inhibit_confirm(
	      MCS_Token_ID                token_id,
	      uint16                      result) {return 0;}

	   	virtual ARM_Error on_token_test_confirm(
	      MCS_Token_ID                token_id,
	      uint16                      result) {return 0;}

	   	virtual ARM_Error on_token_please_indication(
	      MCS_Token_ID                token_id,
	      MCS_User_ID                 requestor) {return 0;}

	   	virtual ARM_Error on_token_give_indication(
	      MCS_Token_ID                token_id,
	      MCS_User_ID                 sender_id) {return 0;}

	   	virtual ARM_Error on_token_give_confirm(
	      MCS_Token_ID                token_id,
	      uint16                      result) {return 0;}

	   	virtual ARM_Error on_handle_allocate_confirm(
	      uint16                      number_of_handles,
	      uint32                      handle_value,
	      GCC_Result                  result) {return 0;}

	   	virtual ARM_Error on_cache_set_confirm(
	      uint32                      cache_handle,
	      GCC_Result                  result) {return 0;}

	   	virtual ARM_Error on_cache_retrive_confirm(
	      uint32                      cache_handle,
	      GCC_Result                  result,
	      uint8*                      data,
	      uint32                      data_length) {return 0;}

	   	virtual ARM_Error on_flow_control_send_ready() { return 0; }

	   	virtual ARM_Error on_misc_msg_indication(
	      uint32                      msg_type,
	      uint32                      msg_data
	      ) { return 0; }

	   	virtual ARM_Error on_data_indication_ex(
	      GCC_Session_Key*            session_key,
	      MCS_User_ID                 sender_id,
	      MCS_Channel_ID              channel_id,
	      boolean                     uniform,
	      MCS_Priority                priority,
	      uint8*                      data,
	      uint32                      data_length,
	      uint8*                      opt_data,
	      uint32                      opt_data_length) { return 0; }

		//{ 20060810, Folki+ for Eureka 4.0 Chat/Polling Cache Design
		virtual ARM_Error on_namehandle_allocate_confirm(
	      uint16					      number_of_handles,
	      NameHandle*						name_handle_list,
	      GCC_Result					   result){ return 0; }

		virtual ARM_Error on_cache_action_confirm_ex(
	      uint32					cache_handle,
			CacheAction				cache_action,
			uint32					reqeust_idx,
			uint32					cache_id,
	      GCC_Result				result){ return 0; }
	
		virtual ARM_Error on_cache_retrieve_confirm_ex(
			uint32							cache_handle,
			uint32							group_id,
			uint32							reqeust_idx,
			uint32							cache_id,
			CacheAction						cache_action,
			GCC_Result						result,
			MCS_Priority					priority,
			uint8*							data,
			uint32							data_length){ return 0; }
		//}
	};
	
	class JAVA_CAS_APE_Sink: public CAS_APE_Sink
	{
	public:
		virtual ~JAVA_CAS_APE_Sink() {};
	public :
		virtual GCC_Error on_detach_indication(
			GCC_Session_Key* session_key,
			GCC_Reason          reason) { return 0; }

		virtual GCC_Error on_data_indication_ex(
			GCC_Session_Key* session_key,
			MCS_User_ID         sender_id,
			MCS_Channel_ID      channel_id,
			boolean             uniform, //////
			MCS_Priority        priority,
			uint8*              user_data,
			uint32              user_data_length,
			uint8*              opt_data,
			uint32              opt_data_length) { return 0; }

		virtual GCC_Error on_data_indication(
			GCC_Session_Key* session_key,
			MCS_User_ID         sender_id,
			MCS_Channel_ID      channel_id,
			boolean             uniform, //////
			MCS_Priority        priority,
			uint8*              user_data,
			uint32              user_data_length) { return 0; }

		virtual GCC_Error on_enroll_confirm(
			GCC_Session_Key* session_key,
			GCC_Result          result) { return 0; }
	};
%}