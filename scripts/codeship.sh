echo "=========================================================="
echo "GAP DEV: Running tests with Semigroups and Grape loaded..."
echo "=========================================================="
echo "(including DigraphsTestExtreme)"
echo "-------------------------------"
echo "LoadPackage(\"digraphs\"); LoadPackage(\"semigroups\"); DigraphsTestAll(); DigraphsTestExtreme(); quit;" | sh gap/bin/gap.sh | tee testlog.txt

echo "=========================================================================="
echo "GAP DEV: Running tests with Semigroups and Grape loaded BEFORE Digraphs..."
echo "=========================================================================="
echo "LoadPackage(\"semigroups\"); LoadPackage(\"grape\"); LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

echo "================================================================"
echo "GAP DEV: Running tests with Grape loaded (but NOT Semigroups)..."
echo "================================================================"
echo "LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

cd gap/pkg/clone
make clean
if (! ./configure CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32); then echo "configure: error" >> testlog.txt; fi
if (! make); then echo "make: error" >> testlog.txt; fi
cd ../../..
echo "==================================================================="
echo "GAP DEV (32-bit): Running tests with Semigroups and Grape loaded..."
echo "==================================================================="
echo "(including DigraphsTestExtreme)"
echo "-------------------------------"
echo "LoadPackage(\"digraphs\"); LoadPackage(\"semigroups\"); DigraphsTestAll(); DigraphsTestExtreme(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

echo "==================================================================================="
echo "GAP DEV (32-bit): Running tests with Semigroups and Grape loaded BEFORE Digraphs..."
echo "==================================================================================="
echo "LoadPackage(\"semigroups\"); LoadPackage(\"grape\"); LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

echo "========================================================================="
echo "GAP DEV (32-bit): Running tests with Grape loaded (but NOT Semigroups)..."
echo "========================================================================="
echo "LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

rm -r gap/pkg/grape

cd gap/pkg/clone
make clean
if (! ./configure); then echo "configure: error" >> testlog.txt; fi
if (! make); then echo "make: error" >> testlog.txt; fi
cd ../../..
echo "================================================================"
echo "GAP DEV: Running tests with Semigroups loaded (but NOT Grape)..."
echo "================================================================"
echo "LoadPackage(\"digraphs\"); LoadPackage(\"semigroups\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

echo "============================================================"
echo "GAP DEV: Running tests WITHOUT Semigroups or Grape loaded..."
echo "============================================================"
echo "LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

cd gap/pkg/clone
make clean
if (! ./configure CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32); then echo "configure: error" >> testlog.txt; fi
if (! make); then echo "make: error" >> testlog.txt; fi
cd ../../..
echo "========================================================================="
echo "GAP DEV (32-bit): Running tests with Semigroups loaded (but NOT Grape)..."
echo "========================================================================="
echo "LoadPackage(\"digraphs\"); LoadPackage(\"semigroups\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

echo "====================================================================="
echo "GAP DEV (32-bit): Running tests WITHOUT Semigroups or Grape loaded..."
echo "====================================================================="
echo "LoadPackage(\"digraphs\"); DigraphsTestAll(); quit;" | sh gap/bin/gap.sh | tee -a testlog.txt

( ! grep -E "########> Diff|brk>|#E|Error|error" testlog.txt )
