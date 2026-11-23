
### Dataset Description

The goal of this dataset is to provide images and the associated annotations to train and validate object detection models. These models can be used in viticulture applications, such as yield estimation, fruit counting, and field robotics.

The dataset was created based on state-of-the-art publicly available sources (see Acknowledgments section) and consists of 11007 RGB images with the related annotations in txt files organized in subfolders, based on the original source. Each annotation file links to its image by the file name.

The images include both single and multiple grape clusters, depending on the source dataset that include both close-range and field-view scenes captured by different cameras, under varying lightning and environmental conditions. Each image contains between one and fifteen annotated grape clusters, depending on the camera distance and scene complexity. Similarly, the dataset includes different variety of grapes from various geographical areas in Europe. The dataset includes also about 204 without grapes.

Please note that some images have typical issues of field data: i) reflections caused by the sun ii) group of grapes partially hidden by leaves or iii) hidden by other objects (e.g. irrigation pipes), iv) color and direction similar to a tree trunk v) dead grapes in the floor or vi) grapes from the plant behind the plant analyzed.

Folders structure and characteristics of the different type of data are reported in table:

Folder |Prefix |  Grape Variety         |   Resolution |  Images  | Boxed clusters  | Masked clusters|
  ---  | ---   | ---                    | ---          | ---      | ---             | --- |
 wgsid |CDY    |     *Chardonnay*       |  2048x1365   |    65    |            840  |             308|
  ---  |CFR    |    *Cabernet Franc*    |  2048x1365   |    65    |          1,069  |             513|
  ---  |CSV    |   *Cabernet Sauvignon* |  2048x1365   |    57    |            643  |             306|
  ---  |SVB    |  *Sauvignon Blanc*     |  2048x1365   |    65    |          1,317  |             608|
  ---  |SYH    | *Syrah*                |  2048x1365   |    48    |            563  |             285|
 AI4A  | ---   |    *Tempranillo*       |  4032x3024   |   247    | ---             |   ---          |
  ---  | ---   |    *Tempranillo*       |  3000x4000   |  ---     | ---             |   ---          |
  ---  | ---   |    *Tempranillo*       |  3264x2448   |  ---     | ---             |   ---          |
wGrape | ---   |   ---                  |  4288x2848   |  247     | ---             |   ---          |
wGrape\without_Bunches | ---   |   ---  |  4288x2848   |  204     | ---             |   ---          |
grapevine| --- |   ---                  |  720x540     |  10009   | ---             |   ---          |
|*Total* | --- |      ---               |       ---    |  11007   | ---             |   ---          |


*General information about the dataset: the grape varieties and the associated identifying prefix, resolution of image capture on field, number of images (instances) and the identified grapes clusters.*

### What data does each instance consist of? 

Each instance contains an RGB image and a text file containing one bounding box description per line.
These text files follows the "YOLO format"

    CLASS CX CY W H

*class* is an integer defining the object class – the dataset presents
only the grape class that is numbered 0, so every line starts with this
“class zero” indicator. The center of the bounding box is the point
*(c_x, c_y)*, represented as float values because this format normalizes
the coordinates by the image dimensions. To get the absolute position,
use *(2048  c_x, 1365  c_y)*. The bounding box dimensions are
given by *W* and *H*, also normalized by the image size.


### Acknowledgments

The data included in this release originate from the sources reported below:

1) Embrapa WGISD: The building of the WGISD dataset was supported by the Embrapa SEG Project 01.14.09.001.05.04, *Image-based metrology for Precision
Agriculture and Phenotyping*, and the CNPq PIBIC Program (grants 161165/2017-6 and 125044/2018-6).

The dataset is available at GitHub (https://github.com/thsant/wgisd).
The data is released under **Creative Commons BY-NC 4.0 (Attribution-NonCommercial 4.0 International license)**  (https://creativecommons.org/licenses/by-nc/4.0/). 

2) AI4Agriculture Grape Dataset
Josep Ramon Morros, Tomas Pariente Lobo, Sergio Salmeron-Majadas, Javier Villazan, Diego Merino, Ana Antunes, Mihai Datcu, Chandrabali Karmakar, Edmundo Guerra, Despina-Athanasia Pantazi & George Stamoulis. (2021). AI4Agriculture Grape Dataset (Version 1.0.0) [Dataset]. 

The dataset is available at https://zenodo.org/records/5660081#.ZGUTO3bMIuW
The data is released under Apache License 2.0

3) Grapevine Bunch Condition Detection Dataset
Isabel Pinheiro. (2023). Grapevine Bunch Condition Detection Dataset [Dataset].

The dataset is available at Zenodo. https://doi.org/10.5281/zenodo.7717014
The data is released under Creative Commons Attribution 4.0 International 

4) wGrapeUNIPD-DL: An open dataset for white grape bunch detection 
Sozzi M, Cantalamessa S, Cogato A, Kayad A, Marinello F. wGrapeUNIPD-DL: An open dataset for white grape bunch detection. Data Brief. 2022 Jul 13;43:108466. doi: 10.1016/j.dib.2022.108466. PMID: 35873279; PMCID: PMC9304721.

The dataset is available at Zenodo https://zenodo.org/record/4066730#.YofMr9hBxPY
The data is released under license cc-by-nc-nd

### No warranty

The maintainers and their institutions are *exempt from any liability,
judicial or extrajudicial, for any losses or damages arising from the
use of the data contained in the image database*.
