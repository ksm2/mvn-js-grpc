import com.google.protobuf.DescriptorProtos;
import com.google.protobuf.DescriptorProtos.FieldDescriptorProto;
import com.google.protobuf.DescriptorProtos.FileDescriptorProto;
import com.google.protobuf.DescriptorProtos.FileDescriptorSet;
import freemarker.template.Configuration;
import freemarker.template.TemplateExceptionHandler;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.stream.Collectors;

public class Main {
    public static void main(String[] args) throws Exception {
        var fileDescriptorSet = runProtoc("example/test.proto");
        var messages = fileDescriptorSet.getFileList()
            .stream()
            .flatMap(file -> file.getMessageTypeList().stream())
            .collect(Collectors.toList());

        var cfg = new Configuration(Configuration.VERSION_2_3_29);
        cfg.setDirectoryForTemplateLoading(new File("src/main/resources"));
        cfg.setDefaultEncoding("UTF-8");
        cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        cfg.setLogTemplateExceptions(false);
        cfg.setWrapUncheckedExceptions(true);
        cfg.setFallbackOnNullLoopVariable(false);

        var template = cfg.getTemplate("test.ts.ftl");
        var out = Files.newBufferedWriter(Paths.get("target/out.ts"));

        var data = new HashMap<String, Object>();
        data.put("fileSet", fileDescriptorSet);
        data.put("helpers", new Helpers());
        template.process(data, out);
    }

    private static FileDescriptorSet runProtoc(String file) throws IOException {
        var pb = new ProcessBuilder("protoc", "--include_source_info", "--descriptor_set_out=/dev/stdout", file);
        var p = pb.start();

        return FileDescriptorSet.parseFrom(p.getInputStream());
    }

    public static class Helpers {
        public String lastSegment(String str) {
            var index = str.lastIndexOf('.');
            return str.substring(index + 1);
        }

        public String lowerCaseFirst(String str) {
            if (str.isBlank()) {
                return str;
            }

            return str.substring(0, 1).toLowerCase() + str.substring(1);
        }

        public String jsType(FieldDescriptorProto field) {
            switch (field.getType()) {
                case TYPE_DOUBLE:
                case TYPE_FLOAT:
                case TYPE_INT64:
                case TYPE_UINT64:
                case TYPE_INT32:
                case TYPE_FIXED64:
                case TYPE_FIXED32:
                case TYPE_UINT32:
                case TYPE_SFIXED32:
                case TYPE_SFIXED64:
                case TYPE_SINT32:
                case TYPE_SINT64:
                    return "number";
                case TYPE_BOOL:
                    return "boolean";
                case TYPE_MESSAGE:
                case TYPE_ENUM:
                    return lowerCaseFirst(field.getTypeName());
                case TYPE_STRING:
                    return "string";
                case TYPE_BYTES:
                    return "Uint8Array";
                default:
                    throw new IllegalArgumentException("Illegal type: " + field.getType());
            }
        }

        public String getMessageComment(FileDescriptorProto file, String indent, int index) {
            for (var location : file.getSourceCodeInfo().getLocationList()) {
                if (locationPathEquals(location, 4, index)) {
                    return wrapDocComment(indent, location.getLeadingComments());
                }
            }
            return "";
        }

        public String getServiceComment(FileDescriptorProto file, String indent, int index) {
            for (var location : file.getSourceCodeInfo().getLocationList()) {
                if (locationPathEquals(location, 6, index)) {
                    return wrapDocComment(indent, location.getLeadingComments());
                }
            }
            return "";
        }

        public String getMethodComment(FileDescriptorProto file, String indent, int service, int method) {
            for (var location : file.getSourceCodeInfo().getLocationList()) {
                if (locationPathEquals(location, 6, service, 2, method)) {
                    return wrapDocComment(indent, location.getLeadingComments());
                }
            }
            return "";
        }

        private boolean locationPathEquals(DescriptorProtos.SourceCodeInfo.Location location, int ...path) {
            if (location.getPathCount() != path.length) {
                return false;
            }

            for (int i = 0; i < path.length; i++) {
                int segment = path[i];
                if (segment != location.getPath(i)) {
                    return false;
                }
            }

            return true;
        }

        private String wrapDocComment(String indent, String comment) {
            if (comment.isBlank()) {
                return "";
            }

            return ("/**\n *" + comment + " */").replaceAll("\n", "\n" + indent);
        }
    }
}
