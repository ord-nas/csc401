import subprocess
import re
import sys
import os

from scipy import stats

models = ["weka.classifiers.functions.SMO",
          "weka.classifiers.bayes.NaiveBayes",
          "weka.classifiers.trees.J48"]

confusion_matrix_pattern = r"""=== Error on test data ===
.*
=== Confusion Matrix ===

\s*a\s*b\s*<-- classified as
\s*([0-9]+)\s*([0-9]+)\s*\|\s*a = 0
\s*([0-9]+)\s*([0-9]+)\s*\|\s*b = 4
"""

def average(values):
    if not values:
        return 0 # No values; avoid division by zero
    else:
        # Otherwise compute average
        return float(sum(values)) / len(values)

def flatten(lsts):
    return sum(lsts, [])

def run(args, pipe_output=False):
    print " ".join(args)
    p = subprocess.Popen(args, stdout = subprocess.PIPE if pipe_output else sys.stdout)
    (out, _) = p.communicate()
    assert p.returncode == 0
    return out

def get_test_accuracy(out):
    m = re.search("=== Error on test data ===\n\n"
                  "Correctly Classified Instances"
                  "\s*([0-9]+)\s*([0-9]+\.[0-9]+)\s+%",
                  out)
    accuracy = float(m.group(2))
    return accuracy

def part_31(output_folder):
    global models
    print "\n3.1 CLASSIFIERS\n"

    output_file = os.path.join(output_folder, "3.1output.txt")
    f = open(output_file, "w")
    f.write("Summary of classifier scores (test accuracy)\n")
    f.write("============================================\n")

    best_accuracy = 0
    best_output = ""
    best_model = ""
    for model in models:
        print "Training model %s ..." % model
        out = run(["java",
                   "-cp",
                   "WEKA/weka.jar",
                   model,
                   "-t",
                   os.path.join(output_folder, "train.arff"),
                   "-T",
                   os.path.join(output_folder, "test.arff"),
                   "-no-cv",
                   "-o"],
                  pipe_output=True)
        print out
        accuracy = get_test_accuracy(out)
        if accuracy > best_accuracy:
            best_accuracy = accuracy
            best_output = out
            best_model = model

        f.write("%s: %f %%\n" % (model, accuracy))

    print "Best classifier: %s" % best_model
    print "Accuracy: %f" % best_accuracy
    print "Writing results to %s ..." % output_file
    f.write("\nBest result: %s\n" % best_model)
    f.write("Training output:\n") 
    f.write(best_output)
    f.close()

    return best_model

def part_32(output_folder, model):
    print "\n3.2 AMOUNT OF TRAINING DATA\n"

    output_file = os.path.join(output_folder, "3.2output.txt")
    f = open(output_file, "w")
    f.write("Training Dataset Size | Test Set Accuracy\n")
    f.write("======================|==================\n")

    for n in xrange(500, 10500, 500):
        print "Running buildarff.py on %d training examples ..." % n
        run(["python",
             "buildarff.py",
             os.path.join(output_folder, "train.twt"),
             os.path.join(output_folder, "train_%d.arff" % n),
             str(n)])
        print "Training model %s on %d training examples ..." % (model, n)
        out = run(["java",
                   "-cp",
                   "WEKA/weka.jar",
                   model,
                   "-t",
                   os.path.join(output_folder, "train_%d.arff" % n),
                   "-T",
                   os.path.join(output_folder, "test.arff"),
                   "-no-cv",
                   "-o"],
                  pipe_output=True)
        accuracy = get_test_accuracy(out)
        f.write("%21d | %f %%\n" % (n, accuracy))
        
    f.close()

def part_33(output_folder, model):
    print "\n3.3 FEATURE ANALYSIS\n"

    output_file = os.path.join(output_folder, "3.3output.txt")
    f = open(output_file, "w")

    for n in [500, 10000]:
        print "Computing information gain on %d examples ..." % n
        f.write("Information gain results for n=%d\n" % n)
        f.write("===============================%s\n" % ("=" * len(str(n))))
        out = run(["sh",
                   "WEKA/infogain.sh",
                   os.path.join(output_folder, "train_%d.arff" % n)],
                  pipe_output=True)
        f.write(out)
        
    f.close()

def part_34(output_folder):
    global models
    print "\n3.4 CROSS-VALIDATION\n"

    output_file = os.path.join(output_folder, "3.4output.txt")
    out_file = open(output_file, "w")
    
    full_arff_file = os.path.join(output_folder, "train.arff")
    with open(full_arff_file, "r") as f:
        in_header = True
        header = ""
        zero = []
        four = []
        for line in f:
            if in_header:
                header += line
            else:
                if line.strip().split(",")[-1] == "0":
                    zero.append(line)
                else:
                    four.append(line)
            if line == "@data\n":
                in_header = False

    num_folds = 10
    print len(zero), len(four)
    print "ZERO:", zero[0], "::::", zero[-1]
    print "FOUR:", four[0], "::::", four[-1]
    assert len(zero) == len(four)
    assert len(zero) % num_folds == 0
    assert len(four) % num_folds == 0
    fold_size = len(zero) / num_folds
    zero_folds = [zero[i*fold_size:(i+1)*fold_size] for i in xrange(num_folds)]
    four_folds = [four[i*fold_size:(i+1)*fold_size] for i in xrange(num_folds)]

    accuracies = []
    for fold in xrange(num_folds):
        # Write the test and train .arff files for this fold
        print "Creating training data for fold %d ..." % fold
        test_file = os.path.join(output_folder, "test_fold_%d.arff" % fold)
        with open(test_file, "w") as f:
            f.write(header)
            f.write("".join(zero_folds[fold]))
            f.write("".join(four_folds[fold]))
        train_file = os.path.join(output_folder, "train_fold_%d.arff" % fold)
        with open(train_file, "w") as f:
            f.write(header)
            f.write("".join(flatten(zero_folds[:fold] + zero_folds[fold+1:])))
            f.write("".join(flatten(four_folds[:fold] + four_folds[fold+1:])))
        
        out_file.write("Fold %d results\n" % fold)
        out_file.write("=====%s========\n\n" % ("=" * len(str(fold))))
        
        out_file.write("Classifier                          | Accuracy | Precision (class 0) | Precision (class 4) | Precision (average) | Recall (class 0) | Recall (class 4) | Recall (average) \n")
        out_file.write("------------------------------------+----------+---------------------+---------------------+---------------------+------------------+------------------+------------------\n")

        # Now train each of the models
        
        fold_accuracies = []
        for model in models:
            print "Running classifier %s on fold %d ..." % (model, fold)
            out = run(["java",
                       "-cp",
                       "WEKA/weka.jar",
                       model,
                       "-t",
                       train_file,
                       "-T",
                       test_file],
                      pipe_output=True)
            m = re.search(confusion_matrix_pattern, out, flags=re.DOTALL)
            assert m
            TN = int(m.group(1))
            FP = int(m.group(2))
            FN = int(m.group(3))
            TP = int(m.group(4))
            accuracy = float(TP+TN) / float(TP+FP+TN+FN)
            fold_accuracies.append(accuracy)
            P_precision = float(TP) / float(TP + FP)
            P_recall = float(TP) / float(TP + FN)
            N_precision = float(TN) / float(TN + FN)
            N_recall = float(TN) / float(TN + FP)
            avg_precision = (P_precision + N_precision) / 2.0
            avg_recall = (P_recall + N_recall) / 2.0

            out_file.write("%35s | %8f | %19f | %19f | %19f | %16f | %16f | %16f \n" % (
                model, accuracy, N_precision, P_precision, avg_precision, N_recall, P_recall, avg_recall))
        out_file.write("\n")
        accuracies.append(fold_accuracies)

    # Transpose accuracies!
    accuracies = zip(*accuracies)

    # Test for significance
    level = 0.05
    out_file.write("Significance tests\n")
    out_file.write("==================\n\n")
    for i in xrange(len(models)):
        for j in xrange(i+1,len(models)):
            direction = "more" if average(accuracies[i]) > average(accuracies[j]) else "less"
            (_, p_value) = stats.ttest_rel(accuracies[i], accuracies[j])
            out_file.write("%s vs. %s: p-value %f\n"% (models[i], models[j], p_value))
            out_file.write("   (%s the null hypothesis at %f significance level)\n" % (
                "REJECT" if p_value < level else "CANNOT REJECT", level))
            out_file.write("   (conclude that %s is %s%s accurate than %s)\n" % (
                models[i], "" if p_value < level else "not significantly ",
                direction, models[j]))
    out_file.close()
    
def main(args):
    if len(args) != 3:
        print "Usage: python classify.py output_folder student_number"
        return

    output_folder = args[1]
    student_number = int(args[2])

    print "Creating output directory %s ..." % output_folder
    os.makedirs(output_folder)

    print "\nPREPROCESSING\n"
    
    print "Running twtt.py on training data ..."
    run(["python",
         "twtt.py",
         "tweets/training.1600000.processed.noemoticon.csv",
         str(student_number),
         os.path.join(output_folder, "train.twt")])

    print "Running twtt.py on testing data ..."
    run(["python",
         "twtt.py",
         "tweets/testdata.manualSUBSET.2009.06.14.csv",
         str(student_number),
         os.path.join(output_folder, "test.twt")])

    print "\nFEATURE EXTRACTION\n"
    
    print "Running buildarff.py on training data ..."
    run(["python",
         "buildarff.py",
         os.path.join(output_folder, "train.twt"),
         os.path.join(output_folder, "train.arff")])

    print "Running buildarff.py on test data ..."
    run(["python",
         "buildarff.py",
         os.path.join(output_folder, "test.twt"),
         os.path.join(output_folder, "test.arff")])

    best_model = part_31(output_folder)
    part_32(output_folder, best_model)
    part_33(output_folder, best_model)
    part_34(output_folder)
            
if __name__ == "__main__":
    main(sys.argv)
