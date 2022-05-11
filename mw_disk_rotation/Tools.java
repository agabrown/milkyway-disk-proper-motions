import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Collections;
import java.util.Comparator;
import java.util.stream.IntStream;

/**
 * Provides functions for use with the animation.
 *
 * @author Anthony Brown May 2022
 *
 */
public final class Tools {

    /**
     * Create a list of indices that indicate how to order the input list of keys (objects that extend Comparable). Thus
     * the list of indices is ordered such that key.get(indx.get(0)) <= key.get(indx.get(1))<= key.get(indx.get(2)) <=
     * etc.
     *
     * <p>
     * Partly based on https://ideone.com/u2OICl.
     * </p>
     *
     * @param key
     *          The list for which to obtain the indices.
     * @return The index list.
     */
    public static final float[] histEqualize(final float[] data) {
        final List<Integer> sortedIndices = sortIndices(toFloatList(data));
        Map<Boolean, List<Integer>> nanPartitioned = IntStream.range(0,
                data.length).boxed().collect(Collectors.partitioningBy(i -> Double.isNaN(data[i])));

        final int nMinOne = nanPartitioned.get(false).size() - 1;
        float[] transformedData = new float[data.length];
        for (int i = 0; i < data.length; i++) {
            transformedData[sortedIndices.get(i)] = Float.isNaN(data[sortedIndices.get(i)]) ? Float.NaN : (float) i /
                nMinOne;
        }
        return transformedData;
    }

    /**
     * Construct the list of indices that specifies in which order to rearrange the elements of the input list such that
     * it is sorted. The input list is not modified.
     *
     * @param list
     *          The list to be rearranged.
     * @param indices
     *          The list of indices specifying in which order to rearrange the
     *          elements of list.
     * @return The rearranged list.
     */
    public static final <T extends Comparable<T>> List<Integer> sortIndices(final List<T> key) {
        if (key.size() < 2) {
            final List<Integer> indices = new ArrayList<>();
            for (int i = 0; i < key.size(); i++) {
                indices.add(i);
            }
            return indices;
        }

        /*
         * Indices of the input list.
         */
        final List<Integer> indices = IntStream.range(0, key.size()).boxed().collect(Collectors.toList());

        /*
         * Sort the indices based on the keys.
         */
        Collections.sort(indices, new Comparator<Integer>() {
            @Override
            public int compare(final Integer i, final Integer j) {
                return key.get(i).compareTo(key.get(j));
            }
        });

        return indices;
    }

    /**
     * Convert an array float[] to a List<Float>.
     *
     * @param array
     *          Input primitive array.
     * @return List (backed by ArrayList) corresponding to input array.
     */
    public static final List<Float> toFloatList(final float[] array) {
        final ArrayList<Float> list = new ArrayList<>();
        for (final float entry : array) {
            list.add(entry);
        }
        list.trimToSize();
        return list;
    }

}
