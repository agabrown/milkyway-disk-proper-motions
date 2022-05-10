import java.awt.Color;
import java.util.EnumSet;

/**
 * Enum that provides colour lookup tables for converting mapped image values (i.e. mapped to the range [0,1]) to
 * java.awt.Colour instances.
 *
 * @author agabrown 18 Jul 2012
 */
public enum ColourLuts {

    /**
     * Matplotlib's magma colour map, which is perceptually uniform.
     */
    MAGMA("Matplotlib's magma colour map, which is perceptually uniform") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.MAGMA.getColour(pixValue);
        }
    },
    /**
     * Matplotlib's inferno colour map, which is perceptually uniform.
     */
    INFERNO("Matplotlib's inferno colour map, which is perceptually uniform") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.INFERNO.getColour(pixValue);
        }
    },
    /**
     * Matplotlib's plasma colour map, which is perceptually uniform.
     */
    PLASMA("Matplotlib's plasma colour map, which is perceptually uniform") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.PLASMA.getColour(pixValue);
        }
    },
    /**
     * Matplotlib's viridis colour map, which is perceptually uniform.
     */
    VIRIDIS("Matplotlib's viridis colour map, which is perceptually uniform") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.VIRIDIS.getColour(pixValue);
        }
    },
    /**
     * Matplotlib's cividis colour map, which is perceptually uniform.
     */
    CIVIDIS("Matplotlib's cividis colour map, which is perceptually uniform") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.CIVIDIS.getColour(pixValue);
        }
    },
    /**
     * Matplotlib's PiYG colour map.
     */
    PIYG("Matplotlib's PiYG colour map") {
        @Override
        protected Color getColour(final double pixValue) {
            return ListedColourLuts.PIYG.getColour(pixValue);
        }
    },
    ;

    /**
     * Descriptive string of colour table.
     */
    private String label;

    /**
     * Constructor.
     *
     * @param lab Descriptive string of colour table.
     */
    ColourLuts(final String lab) {
        label = lab;
    }

    /**
     * Override the default toString() method for enum types so that a more readable string is returned whenever the
     * values are to be converted to strings.
     *
     * @return label
     */
    @Override
    public String toString() {
        return label;
    }

    /**
     * Given a pixel value scaled between zero and one return the colour from the lookup table selected when
     * constructing the instance of this class.
     *
     * @param pixValue Image pixel value scaled between 0 and 1.
     * @return The colour from the LUT.
     */
    protected abstract Color getColour(double pixValue);

    /**
     * Obtain a corresponding instance of the ColourLut class.
     *
     * @return A fresh ColourLut instance.
     */
    public ColourLut getLut() {
        return new ColourLut.Builder(this).invert(false).discretize(0).setAlpha(1f).setGamma(1.0).build();
    }

    /**
     * Return all the LUTs defined in this Enum as an array.
     *
     * @return Array of all look-up tables.
     */
    public static ColourLuts[] toArray() {
        return EnumSet.allOf(ColourLuts.class).toArray(new ColourLuts[0]);
    }

}
