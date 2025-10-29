/* DerivedInductionVar.cpp
 *
 * This pass detects derived induction variables using ScalarEvolution.
 * For affine derived IVs (SCEVAddRecExpr && isAffine()), we synthesize
 * `start + step * canonicalIV` directly in the loop header (first non-PHI).
 *
 * Compatible with New Pass Manager
 */

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Value.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ScalarEvolutionExpander.h"
#include "llvm/IR/IRBuilder.h"

using namespace llvm;

namespace {

class DerivedInductionVars : public PassInfoMixin<DerivedInductionVars> {
 public:
  PreservedAnalyses run(Function& F, FunctionAnalysisManager& AM) {
    errs() << "--- DerivedInductionVar Pass START ---\n";
    auto& LI = AM.getResult<LoopAnalysis>(F);
    auto& SE = AM.getResult<ScalarEvolutionAnalysis>(F);

    bool changed = false;
    for (Loop* L : LI) {
      if (analyzeLoopRecursively(L, SE)) changed = true;
    }

    if (changed) {
      return PreservedAnalyses::none();
    } else {
      return PreservedAnalyses::all();
    }
  }

  bool analyzeLoopRecursively(Loop* L, ScalarEvolution& SE) {
    errs().indent(L->getLoopDepth() * 2);
    errs() << "Analyzing Loop: " << L->getHeader()->getName() << "\n";
    bool loop_flag = false;

    SmallVector<PHINode*, 8> DeadPHIs;

    BasicBlock* Header = L->getHeader();
    if (!Header) return false;

    Instruction* HeaderInsert = Header->getFirstNonPHI();
    if (!HeaderInsert) {
      errs().indent(L->getLoopDepth() * 2 + 2);
      errs() << "Header has no non-PHI instruction; skipping loop: "
             << Header->getName() << "\n";
      return false;
    }

    // Preheader insertion point
    BasicBlock *Preheader = L->getLoopPreheader();
    Instruction *PreheaderInsert = nullptr;
    if (Preheader)
      PreheaderInsert = Preheader->getTerminator();

    SCEVExpander Expander(SE, Header->getModule()->getDataLayout(), "iv.expanded");

    for (PHINode& PN : Header->phis()) {
      if (!PN.getType()->isIntegerTy()) continue;

      const SCEV* S = SE.getSCEV(&PN);

      if (auto* AR = dyn_cast<SCEVAddRecExpr>(S)) {
        // Check this add recurrence belongs to the current loop and is affine
        if (AR->getLoop() == L && AR->isAffine()) {
          const SCEV* StepSCEV = AR->getStepRecurrence(SE);
          const SCEV* StartSCEV = AR->getStart();

          PHINode* BasicIV = L->getCanonicalInductionVariable();
          if (!BasicIV) {
            errs().indent(L->getLoopDepth() * 2 + 2);
            errs() << "No canonical IV; skipping: " << PN.getName() << "\n";
            continue;
          }

          const SCEV* BasicIV_SCEV = SE.getSCEV(BasicIV);
          const SCEV* DerivedIV_SCEV = S;

          if (!Expander.isSafeToExpand(DerivedIV_SCEV) ||
              DerivedIV_SCEV == BasicIV_SCEV) {
            errs().indent(L->getLoopDepth() * 2 + 2);
            errs() << "Skipping unsafe-to-expand IV: " << PN.getName() << "\n";
            continue;
          }

          Value *StartVal = nullptr;
          Value *StepVal = nullptr;

          if (auto *SC = dyn_cast<SCEVConstant>(StartSCEV)) {
            StartVal = SC->getValue();
          }
          if (auto *SC = dyn_cast<SCEVConstant>(StepSCEV)) {
            StepVal = SC->getValue();
          }

          if (!StartVal || !StepVal) {
            if (!PreheaderInsert) {
              errs().indent(L->getLoopDepth() * 2 + 2);
              errs() << "No preheader available to materialize non-constant start/step; skipping: "
                     << PN.getName() << "\n";
              continue;
            }
            if (!StartVal) {
              StartVal = Expander.expandCodeFor(StartSCEV, PN.getType(), PreheaderInsert);
              if (!StartVal) {
                errs().indent(L->getLoopDepth() * 2 + 2);
                errs() << "Failed to materialize Start for: " << PN.getName() << "\n";
                continue;
              }
            }
            if (!StepVal) {
              StepVal = Expander.expandCodeFor(StepSCEV, PN.getType(), PreheaderInsert);
              if (!StepVal) {
                errs().indent(L->getLoopDepth() * 2 + 2);
                errs() << "Failed to materialize Step for: " << PN.getName() << "\n";
                continue;
              }
            }
          }

          IRBuilder<> B(HeaderInsert);

          Value *Mul = B.CreateMul(BasicIV, StepVal, PN.getName() + ".stepmul");
          Value *NewVal = B.CreateAdd(StartVal, Mul, PN.getName() + ".expanded");

          PN.replaceAllUsesWith(NewVal);
          SE.forgetValue(&PN);
          DeadPHIs.push_back(&PN);
          loop_flag = true;

          errs().indent(L->getLoopDepth() * 2 + 2);
          errs() << "Found Derived IV: " << PN.getName() << " = {" << *StartSCEV
                 << ",+, " << *StepSCEV << "}\n";
        }
      }
    }

    for (auto Dead : DeadPHIs) {
      Dead->eraseFromParent();
    }

    for (auto* SubLoop : L->getSubLoops()) analyzeLoopRecursively(SubLoop, SE);

    return loop_flag;
  }
};

}  // namespace

// Register the pass
llvm::PassPluginLibraryInfo getDerivedInductionVarPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "DerivedInductionVars", LLVM_VERSION_STRING,
          [](PassBuilder& PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager& FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "derived-iv") {
                    FPM.addPass(DerivedInductionVars());
                    return true;
                  }
                  return false;
                });
          }};
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getDerivedInductionVarPluginInfo();
}
