import java.awt.Color;

/**
 * Provides static method for creating and manipulating colours.
 *
 * @author agabrown Jan 2016
 */
public final class ColorFactory {

    /**
     * Obtain a transparent version of the input colour.
     *
     * @param color Input colour.
     * @param alpha Transparency parameter, between 0 and 1, where 0 is totally transparent.
     * @return Transparent version of input colour.
     */
    public static Color getTransparentColor(final Color color, final float alpha) {
        return new Color(color.getColorSpace(), color.getColorComponents(null), alpha);
    }
}
