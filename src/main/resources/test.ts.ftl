<#-- @ftlvariable name="helpers" type="Main.Helpers" -->
<#-- @ftlvariable name="fileSet" type="com.google.protobuf.DescriptorProtos.FileDescriptorSet" -->
// Files: ${fileSet.fileCount}
import { BinaryReader, BinaryWriter, Message } from 'google-protobuf';
import { Observable } from 'rxjs';

interface Metadata {
  has(key: string): boolean;
  get(key: string): string;
  getBinary(key: string): Uint8Array;
  set(key: string, value: string): this;
  setBinary(key: string, value: Uint8Array): this;
  delete(key: string, value: string): boolean;
  clear(): void;
}

export type ServerUnaryRequest<Q> = Q;
export type ServerStreamRequest<Q> = Observable<Q>;
export type ServerUnaryResponse<R> = R | Promise<R> | Observable<R>;
export type ServerStreamResponse<R> = Observable<R>;

interface Server {
  registerUnaryHandler<Q, R>(method: string, handler: (request: ServerUnaryRequest<Q>, metadata: Metadata) => ServerUnaryResponse<R>): void;
  registerServerStreamHandler<Q, R>(method: string, handler: (request: ServerUnaryRequest<Q>, metadata: Metadata) => ServerStreamResponse<R>): void;
  registerClientStreamHandler<Q, R>(method: string, handler: (request: ServerStreamRequest<Q>, metadata: Metadata) => ServerUnaryResponse<R>): void;
  registerBidiStreamHandler<Q, R>(method: string, handler: (request: ServerStreamRequest<Q>, metadata: Metadata) => ServerStreamResponse<R>): void;
}

export type ClientUnaryRequest<Q> = Q;
export type ClientStreamRequest<Q> = Observable<Q>;
export type ClientUnaryResponse<R> = Observable<R>;
export type ClientStreamResponse<R> = Observable<R>;

interface Client {
  makeUnaryRequest<Q, R>(method: string, request: ClientUnaryRequest<Q>, metadata?: Metadata): ClientUnaryResponse<R>;
  makeServerStreamRequest<Q, R>(method: string, request: ClientUnaryRequest<Q>, metadata?: Metadata): ClientStreamResponse<R>;
  makeClientStreamRequest<Q, R>(method: string, request: ClientStreamRequest<Q>, metadata?: Metadata): ClientUnaryResponse<R>;
  makeBidiStreamRequest<Q, R>(method: string, request: ClientStreamRequest<Q>, metadata?: Metadata): ClientStreamResponse<R>;
}

<#list fileSet.fileList as file>
// ${file.name}
<#list file.serviceList as service>

${helpers.getServiceComment(file, "", service?index)}
export abstract class ${service.name}Server {
  /**
   * Register methods with the given server.
   *
   * @param server - The server to register on
   */
  register(server: Server): void {
  <#list service.methodList as method>
    server.register${helpers.methodMode(method)}Handler<${helpers.lastSegment(method.inputType)}, ${helpers.lastSegment(method.outputType)}>('${method.name}', (req, md) => this.${helpers.lowerCaseFirst(method.name)}(req, md));
  </#list>
  }
  <#list service.methodList as method>

  ${helpers.getMethodComment(file, "  ", service?index, method?index)}
  abstract ${helpers.lowerCaseFirst(method.name)}(request: <#if method.clientStreaming>ServerStreamRequest<#else>ServerUnaryRequest</#if><${helpers.lastSegment(method.inputType)}>, metadata: Metadata): <#if method.serverStreaming>ServerStreamResponse<#else>ServerUnaryResponse</#if><${helpers.lastSegment(method.outputType)}>;
  </#list>
}

${helpers.getServiceComment(file, "", service?index)}
export class ${service.name}Client {
  private readonly client: Client;

  constructor(client: Client) {
    this.client = client;
  }
  <#list service.methodList as method>

  ${helpers.getMethodComment(file, "  ", service?index, method?index)}
  ${helpers.lowerCaseFirst(method.name)}(request: <#if method.clientStreaming>ClientStreamRequest<#else>ClientUnaryRequest</#if><${helpers.lastSegment(method.inputType)}>, metadata?: Metadata): <#if method.serverStreaming>ClientStreamResponse<#else>ClientUnaryResponse</#if><${helpers.lastSegment(method.outputType)}> {
    return this.client.make${helpers.methodMode(method)}Request('${method.name}', request, metadata);
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
    return {
      <#list message.fieldList as field>
      ${field.jsonName}: this.${field.jsonName},
      </#list>
    };
  }
}
</#list>
</#list>
