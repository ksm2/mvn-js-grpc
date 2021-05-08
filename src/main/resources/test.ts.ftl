<#-- @ftlvariable name="helpers" type="Main.Helpers" -->
<#-- @ftlvariable name="fileSet" type="com.google.protobuf.DescriptorProtos.FileDescriptorSet" -->
// Files: ${fileSet.fileCount}
import { BinaryReader, BinaryWriter, Message } from 'google-protobuf';
import { Observable } from 'rxjs';

export type UnaryReq<Q> = Q;
export type StreamReq<Q> = Observable<Q>;
export type UnaryRes<R> = R | Promise<R> | Observable<R>;
export type StreamRes<R> = Observable<R>;

<#list fileSet.fileList as file>
// ${file.name}
<#list file.serviceList as service>

${helpers.getServiceComment(file, "", service?index)}
export class ${service.name} {
  <#list service.methodList as method>

  ${helpers.getMethodComment(file, "  ", service?index, method?index)}
  ${helpers.lowerCaseFirst(method.name)}(request: <#if method.clientStreaming>StreamReq<#else>UnaryReq</#if><${helpers.lastSegment(method.inputType)}>): <#if method.serverStreaming>StreamRes<#else>UnaryRes</#if><${helpers.lastSegment(method.outputType)}> {
    throw new Error("This is not implemented.");
  }
  </#list>
}
</#list>
<#list file.messageTypeList as message>

${helpers.getMessageComment(file, "", message?index)}
export class ${message.name} extends Message {
  <#list message.fieldList as field>

  get ${field.jsonName}(): ${helpers.jsType(field)} {
    return Message.getField(this, ${field.number}) as ${helpers.jsType(field)};
  }

  set ${field.jsonName}(value: ${helpers.jsType(field)}) {
    Message.setField(this, ${field.number}, value);
  }
  </#list>

  serializeBinary(): Uint8Array {
    return new Uint8Array([]); // TODO
  }

  toObject(includeInstance?: boolean): {} {
    return {};
  }
}
</#list>
</#list>
