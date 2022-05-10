import java.awt.Color;

/**
 * This class represents a colour look-up table (LUT) for false colour images or for plots with data points colour coded
 * according to some auxiliary variable. Instances of this class should be obtained through the ColourLuts enum.
 *
 * @author agabrown Feb 2016 - Aug 2016
 */
public class ColourLut implements ColourLookUpTable {

    /**
     * Holds the LUT as defined in the ColourLuts enum.
     */
    private final ColourLuts lut;

    /**
     * If true the colour LUT is inverted.
     */
    private final boolean invert;

    /**
     * Number of colours to use from the total available (at least 1). If the value is less than or equal to zero no
     * discretization is applied.
     */
    private final int nDiscrete;

    /**
     * The transparency (alpha value) for all colours in this colour LUT.
     */
    private final float alpha;

    /**
     * The value of the gamma correction for the colour LUT.
     */
    private final double gamma;

    /**
     * Defines a fully transparent (invisible) color for handling NaN values.
     */
    private final Color transparent = new Color(0, 0, 0, 0);

    /**
     * Implements the Builder pattern for the ColourLut class.
     */
    protected static class Builder {

        /**
         * The ColourLuts enum wrapped by this ColourLut.
         */
        private final ColourLuts lut;

        /**
         * If true invert the colour LUT.
         */
        private boolean invert = false;

        /**
         * If >0 use only the indicated number of colours from the colour LUT.
         */
        private int nDiscrete = 0;

        /**
         * Transparency for all colours in this colour LUT.
         */
        private float alpha = 1f;

        /**
         * The value of the gamma correction for the colour LUT.
         */
        private double gamma = 1.0;

        /**
         * Constructor.
         *
         * @param cl ColourLuts enum wrapped by this ColourLut.
         */
        protected Builder(final ColourLuts cl) {
            lut = cl;
        }

        /**
         * Set whether or not to invert the LUT.
         *
         * @param inv If true invert the colour LUT.
         * @return The builder instance.
         */
        protected Builder invert(final boolean inv) {
            invert = inv;
            return this;
        }

        /**
         * Discretize the LUT to a limited number of colours.
         *
         * @param n Number of colour from LUT to use.
         * @return The builder instance.
         */
        protected Builder discretize(final int n) {
            if (n < 1) {
                nDiscrete = 0;
            } else {
                nDiscrete = n;
            }
            return this;
        }

        /**
         * Set the transparency for all colours in this LUT.
         *
         * @param a Transparency (alpha) value between 0 and 1.
         * @return The builder instance.
         */
        protected Builder setAlpha(final float a) {
            if (alpha < 0f || alpha > 1f) {
                alpha = 1f;
            } else {
                alpha = a;
            }
            return this;
        }

        /**
         * Set the value of the Gamma correction.
         *
         * @param g The gamma correction.
         * @return The builder instance.
         */
        protected Builder setGamma(final double g) {
            gamma = g;
            return this;
        }

        /**
         * Construct a new ColourLut instance.
         *
         * @return A fresh ColourLut instance.
         */
        protected final ColourLut build() {
            return new ColourLut(this);
        }
    }

    /**
     * Constructor.
     *
     * @param builder The builder instance with the class initialization information.
     */
    private ColourLut(final Builder builder) {
        this.lut = builder.lut;
        this.invert = builder.invert;
        this.nDiscrete = builder.nDiscrete;
        this.alpha = builder.alpha;
        this.gamma = builder.gamma;
    }

    @Override
    public ColourLookUpTable invert() {
        return new ColourLut.Builder(lut).invert(!invert).discretize(nDiscrete).setAlpha(alpha).setGamma(gamma).build();
    }

    @Override
    public ColourLookUpTable discretize(final int n) {
        return new ColourLut.Builder(lut).invert(invert).discretize(n).setAlpha(alpha).setGamma(gamma).build();
    }

    @Override
    public ColourLookUpTable setAlpha(final float a) {
        return new ColourLut.Builder(lut).invert(invert).discretize(nDiscrete).setAlpha(a).setGamma(gamma).build();
    }

    @Override
    public ColourLookUpTable setGamma(final double g) {
        return new ColourLut.Builder(lut).invert(invert).discretize(nDiscrete).setAlpha(alpha).setGamma(g).build();
    }

    @Override
    public Color getColour(final double pixValue) {
        if (Double.isNaN(pixValue)) {
            return transparent;
        }
        double pv;
        if (gamma == 1f) {
            pv = pixValue;
        } else {
            pv = Math.pow(pixValue, gamma);
        }
        if (nDiscrete > 1) {
            pv = pixValue >= 1.0 ? 1.0 : Math.floor(nDiscrete * pixValue) / (nDiscrete - 1);
        } else if (nDiscrete == 1) {
            pv = 0.0;
        }
        if (invert) {
            return ColorFactory.getTransparentColor(lut.getColour(1.0 - pv), alpha);
        } else {
            return ColorFactory.getTransparentColor(lut.getColour(pv), alpha);
        }
    }

    /**
     * Get the ordinal value (index in list) of the ColourLuts enum contained in this ColourLut.
     *
     * @return The ordinal of the ColourLuts enum.
     */
    public int getColourLutsOrdinal() {
        return lut.ordinal();
    }

    @Override
    public String toString() {
        if (invert) {
            return lut.toString() + ": inverted";
        } else {
            return lut.toString();
        }
    }

}
