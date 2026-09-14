/*
 * This source file and its compiled companion (helper.jar) form a tiny,
 * self-contained example that exercises PreTeXt's "file" element with
 * @format = "binary" and @source pointing at an actual compiled Java
 * archive.  In the sample book (examples/sample-book/rune.xml) a program
 * with @add-files referencing this file makes the class available to
 * server-side (Jobe) execution.
 *
 * To rebuild the archive after editing this source:
 *
 *   javac helper.java
 *   jar cfe helper.jar Helper helper.class
 *
 * PreTeXt stores a base64 (text) representation of the binary file in the
 * generated "gen/datafile/" directory; the Runestone renderer registers it
 * with the browser as a hidden payload flagged with "data-isbinary" so a
 * future Runestone can hand it to a server verbatim.
 */
public class Helper {
    /** The square of n. */
    public static int square(int n) {
        return n * n;
    }
}
