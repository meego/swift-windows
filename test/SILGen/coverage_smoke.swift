// RUN: rm -rf %t && mkdir %t
// RUN: %target-build-swift %s -profile-generate -profile-coverage-mapping -Xfrontend -disable-incremental-llvm-codegen -o %t/main
// RUN: env LLVM_PROFILE_FILE=%t/default.profraw %target-run %t/main
// RUN: %llvm-profdata merge %t/default.profraw -o %t/default.profdata
// RUN: %llvm-profdata show %t/default.profdata -function=f_internal | FileCheck %s --check-prefix=CHECK-INTERNAL
// RUN: %llvm-profdata show %t/default.profdata -function=f_private | FileCheck %s --check-prefix=CHECK-PRIVATE
// RUN: %llvm-profdata show %t/default.profdata -function=f_public | FileCheck %s --check-prefix=CHECK-PUBLIC
// RUN: %llvm-profdata show %t/default.profdata -function=main | FileCheck %s --check-prefix=CHECK-MAIN
// RUN: %llvm-cov show %t/main -instr-profile=%t/default.profdata | FileCheck %s --check-prefix=CHECK-COV
// RUN: rm -rf %t

// REQUIRES: profile_runtime
// REQUIRES: OS=macosx
// XFAIL: asan

// CHECK-INTERNAL: Functions shown: 1
// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}func f_internal
internal func f_internal() {}

// CHECK-PRIVATE: Functions shown: 1
// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}func f_private
private func f_private() { f_internal() }

// CHECK-PUBLIC: Functions shown: 1
// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}func f_public
public func f_public() { f_private() }

class Class1 {
  var Field1 = 0

// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}init
  init() {}

// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}deinit
  deinit {}
}

// CHECK-MAIN: Maximum function count: 1
func main() {
// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}f_public
  f_public()

// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}if (true)
  if (true) {}

  var x : Int32 = 0
  while (x < 10) {
// CHECK-COV: 10|{{.*}}[[@LINE+1]]|{{.*}}x += 1
    x += 1
  }

// CHECK-COV: 1|{{.*}}[[@LINE+1]]|{{.*}}Class1
  let _ = Class1()
}

// rdar://problem/22761498 - enum declaration suppresses coverage
func foo() {
  var x : Int32 = 0   // CHECK-COV: 1|{{.*}}[[@LINE]]
  enum ETy { case A } // CHECK-COV: 1|{{.*}}[[@LINE]]
  repeat {            // CHECK-COV: 1|{{.*}}[[@LINE]]
    x += 1            // CHECK-COV: 1|{{.*}}[[@LINE]]
  } while x == 0      // CHECK-COV: 1|{{.*}}[[@LINE]]
  x += 1              // CHECK-COV: 1|{{.*}}[[@LINE]]
}

main()
foo()
