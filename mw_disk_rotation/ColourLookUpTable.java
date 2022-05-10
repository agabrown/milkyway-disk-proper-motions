import java.awt.Color;

/**
 * Interface for colour lookup tables.
 *
 * @author agabrown May 2016 - Aug 2016
 */
public interface ColourLookUpTable {

    /**
     * Obtain and inverted version of this colour LUT.
     *
     * @return A new instance representing the reverse of the current colour LUT.
     */
    ColourLookUpTable invert();

    /**
     * Use only {@code n} colours out of all possible colours in this colour LUT. The {@code n} colours are chosen
     * evenly spread out over the colour table.
     *
     * @param n Number of discrete colours to use (at least 1);
     * @return A new instance representing the discretized version of this colour LUT.
     */
    ColourLookUpTable discretize(int n);

    /**
     * Set the transparency (alpha channel) for all colours in this colour LUT.
     *
     * @param a The transparency value for the colours. Between 0 and 1, where 0 means totally transparent.
     * @return A new instance representing the transparent version of this colour LUT.
     */
    ColourLookUpTable setAlpha(float a);

    /**
     * Set the value of the Gamma correction. This means that after the scaling of the data value the following
     * transformation is applied to the normalized data values:
     *
     * <pre>
     *   {@code V_out = V_in^gamma}
     * </pre>
     *
     * @param g The value of the gamma correction.
     * @return A new instance representing the version of this colour LUT with the input value of gamma.
     */
    ColourLookUpTable setGamma(double g);

    /**
     * Given a pixel value scaled between zero and one return the colour from the lookup table. For NaN values the
     * colour returned should be fully transparent.
     *
     * @param pixValue Image pixel value scaled between 0 and 1.
     * @return The colour from the LUT.
     */
    Color getColour(final double pixValue);

}
