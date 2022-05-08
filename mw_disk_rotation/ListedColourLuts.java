import java.awt.Color;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * This class represents a colour lookup table which generates the colours from an internal list. This is useful in case
 * no simple formulas are available to describe the LUT. Instances of this class should be obtained through the
 * ColourLuts enum.
 *
 * @author agabrown Aug 2016 - May 2022.
 */
public enum ListedColourLuts {

    /**
     * The magma colour map from Matplotlib.
     */
    MAGMA("Colour table for MatplotLib's magma colour map", ListedColourData.MAGMA_DATA) {
    },
    /**
     * The inferno colour map from Matplotlib.
     */
    INFERNO("Colour table for MatplotLib's inferno colour map", ListedColourData.INFERNO_DATA) {
    },
    /**
     * The plasma colour map from Matplotlib.
     */
    PLASMA("Colour table for MatplotLib's plasma colour map", ListedColourData.PLASMA_DATA) {
    },
    /**
     * The viridis colour map from Matplotlib.
     */
    VIRIDIS("Colour table for MatplotLib's viridis colour map", ListedColourData.VIRIDIS_DATA) {
    },
    /**
     * The cividis colour map from Matplotlib.
     */
    CIVIDIS("Colour table for MatplotLib's cividis colour map", ListedColourData.CIVIDIS_DATA) {
    },
    ;

    /**
     * Descriptive string of colour table.
     */
    private String label;

    /**
     * List of colour representing the listed LUT.
     */
    private List<Color> colourList;

    /**
     * Constructor.
     *
     * @param lab Descriptive string of colour table.
     */
    ListedColourLuts(final String lab, final double[][] listedLut) {
        label = lab;
        colourList = createColourList(listedLut);
    }

    /**
     * String representation of the colour table.
     *
     * @return Descriptive string for this colour table.
     */
    @Override
    public String toString() {
        return label;
    }

    /**
     * Create this listed colour LUT from the data in {@link ListedColourData}.
     *
     * @param listedLut The raw data for this listed colour LUT.
     * @return The list of colours for this listed colour LUT.
     */
    private List<Color> createColourList(final double[][] listedLut) {
        final List<Color> result = new ArrayList<>();
        for (final double[] rgb : listedLut) {
            result.add(new Color((float) rgb[0], (float) rgb[1], (float) rgb[2]));
        }
        return Collections.unmodifiableList(result);
    }

    /**
     * Get the colour for the input pixel value scaled between zero and one.
     *
     * @param pixValue The scaled pixel value
     * @return The colour for the input pixel value.
     */
    protected Color getColour(final double pixValue) {
        final int index = (int) Math.round(pixValue * (colourList.size() - 1) - 0.5);
        if (index == colourList.size() - 1) {
            return colourList.get(colourList.size() - 1);
        } else if (index == 0) {
            return colourList.get(0);
        } else {
            final float low = index / (float) colourList.size();
            final float delta = (float) (pixValue - low);
            final float[] leftRGB = colourList.get(index).getColorComponents(null);
            final float[] rightRGB = colourList.get(index + 1).getColorComponents(null);
            return new Color(leftRGB[0] + delta * (rightRGB[0] - leftRGB[0]), leftRGB[1] + delta * (rightRGB[1] - leftRGB[1]),
                    leftRGB[2] + delta * (rightRGB[2] - leftRGB[2]));
        }
    }

}
