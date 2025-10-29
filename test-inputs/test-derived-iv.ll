; test-derived-iv.ll
define void @test_derived_iv(i32 %n) {
entry:
  ; This initial block will become the preheader after loop-simplify
  br label %loop.header

loop.header:
  ; 1. Canonical IV (i): {0,+,1}
  %i.0 = phi i32 [ 0, %entry ], [ %i.next, %loop.latch ]
  
  ; 2. Derived IV (j): {100,+,5}
  %j.0 = phi i32 [ 100, %entry ], [ %j.next, %loop.latch ] 
  
  %cmp = icmp slt i32 %i.0, %n
  br i1 %cmp, label %loop.body, label %loop.exit

loop.body:
  ; A dummy instruction using the D-IV to prevent its Dead Code Elimination
  %use = add i32 %j.0, 1
  
  br label %loop.latch

loop.latch:
  %i.next = add nsw i32 %i.0, 1  ; IV step
  %j.next = add nsw i32 %j.0, 5  ; D-IV step
  
  br label %loop.header

loop.exit:
  ret void
}