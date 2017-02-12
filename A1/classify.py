import subprocess
import re
import sys
import os

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
    print "\n3.1 CLASSIFIERS\n"

    models = ["weka.classifiers.functions.SMO",
              "weka.classifiers.bayes.NaiveBayes",
              "weka.classifiers.trees.J48"]

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
        f.write("===============================%s\n" % "".join("=" for _ in str(n)))
        out = run(["sh",
                   "WEKA/infogain.sh",
                   os.path.join(output_folder, "train_%d.arff" % n)],
                  pipe_output=True)
        f.write(out)
        
    f.close()
        
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

            
if __name__ == "__main__":
    main(sys.argv)
