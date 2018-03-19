fixMethod('LBYFixDemo2', 'classMightCrash:', 1, true,
          function(className, originInvocation, originArguments) {
          if (originArguments[0] == null) {
          runErrorBranch('LBYFixDemo2', 'classMightCrash');
          } else {
          runInvocation(originInvocation);
          }
          });
