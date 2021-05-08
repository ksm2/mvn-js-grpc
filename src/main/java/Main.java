import com.google.protobuf.DescriptorProtos.FileDescriptorSet;

import java.io.IOException;
import java.util.stream.Collectors;

public class Main {
    public static void main(String[] args) throws Exception {
        var fileDescriptorSet = runProtoc("example/test.proto");
        var messages = fileDescriptorSet.getFileList()
            .stream()
            .flatMap(file -> file.getMessageTypeList().stream())
            .collect(Collectors.toList());

        System.out.println(messages);
    }

    private static FileDescriptorSet runProtoc(String file) throws IOException {
        var pb = new ProcessBuilder("protoc", "--descriptor_set_out=/dev/stdout", file);
        var p = pb.start();

        return FileDescriptorSet.parseFrom(p.getInputStream());
    }
}
